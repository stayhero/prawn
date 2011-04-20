# encoding: ASCII-8BIT

# png.rb : Extracts the data from a PNG that is needed for embedding
#
# Based on some similar code in PDF::Writer by Austin Ziegler
#
# Copyright April 2008, James Healy.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'stringio'
require 'enumerator'
require 'chunky_png'

module Prawn
  module Images
    # A convenience class that wraps the logic for extracting the parts
    # of a PNG image that we need to embed them in a PDF
    #
    class PNG < Image
      attr_reader :img_data, :alpha_channel
      attr_reader :width, :height, :bits
      attr_reader :color_type
      attr_accessor :scaled_width, :scaled_height

      def self.can_render?(image_blob)
        image_blob[0, 8].unpack("C*") == [137, 80, 78, 71, 13, 10, 26, 10]
      end

      # Process a new PNG image
      #
      # <tt>data</tt>:: A binary string of PNG data
      #
      def initialize(data)
        @chunky = ChunkyPNG::Image.from_blob(data)
        @width  = @chunky.width
        @height = @chunky.height
        @bits   = 8
        @img_data, @alpha_channel = unfilter_image_data
      end

      # number of color components to each pixel
      #
      def colors
        3
      end

      def alpha_channel?
        true
      end

      # Adobe Reader can't handle 16-bit png channels -- chop off the second
      # byte (least significant)
      #
      def alpha_channel_bits
        8
      end

      # Build a PDF object representing this image in +document+, and return
      # a Reference to it.
      #
      def build_pdf_object(document)
        # build the image dict
        obj = document.ref!(
          :Type             => :XObject,
          :Subtype          => :Image,
          :Height           => height,
          :Width            => width,
          :BitsPerComponent => bits,
          :Length           => @img_data.size,
          :Filter           => :FlateDecode,
          :ColorSpace       => :DeviceRGB
        )

        # append the actual image data to the object as a stream
        obj << img_data
        smask_obj = document.ref!(
          :Type             => :XObject,
          :Subtype          => :Image,
          :Height           => self.height,
          :Width            => self.width,
          :BitsPerComponent => 8,
          :Length           => self.alpha_channel.size,
          :Filter           => :FlateDecode,
          :ColorSpace       => :DeviceGray,
          :Decode           => [0, 1]
        )
        smask_obj << alpha_channel
        obj.data[:SMask] = smask_obj

        obj
      end

      # Returns the minimum PDF version required to support this image.
      def min_pdf_version
        if bits > 8
          # 16-bit color only supported in 1.5+ (ISO 32000-1:2008 8.9.5.1)
          1.5
        elsif alpha_channel?
          # Need transparency for SMask
          1.4
        else
          1.0
        end
      end

      private

      def unfilter_image_data
        img_data = ""
        alpha_channel = ""

        @chunky.pixels.each do |int|
          img_data << [
            ChunkyPNG::Color.r(int),
            ChunkyPNG::Color.g(int),
            ChunkyPNG::Color.b(int)
          ].pack("CCC")

          alpha_channel << [
            ChunkyPNG::Color.a(int)
          ].pack("C")
        end

        return Zlib::Deflate.deflate(img_data), Zlib::Deflate.deflate(alpha_channel)
      end
    end
  end
end
