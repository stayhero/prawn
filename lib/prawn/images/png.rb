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
      attr_reader :width, :height
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
        @img_data = extract_image_data
        @alpha_channel = extract_alpha_channel
      end

      def alpha_channel?
        @alpha_channel != nil
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
          :ColorSpace       => colorspace
        )

        # append the actual image data to the object as a stream
        obj << @img_data

        if @alpha_channel
          smask_obj = document.ref!(
            :Type             => :XObject,
            :Subtype          => :Image,
            :Height           => self.height,
            :Width            => self.width,
            :BitsPerComponent => 8,
            :Length           => @alpha_channel.size,
            :Filter           => :FlateDecode,
            :ColorSpace       => :DeviceGray,
            :Decode           => [0, 1]
          )
          smask_obj << @alpha_channel
          obj.data[:SMask] = smask_obj
        end

        obj
      end

      # Returns the minimum PDF version required to support this image.
      #
      # Need transparency for SMask
      #
      def min_pdf_version
        1.4
      end

      def bits
        8
      end

      def colorspace
        if @chunky.palette.grayscale?
          :DeviceGray
        else
          :DeviceRGB
        end
      end

      private

      def extract_image_data
        if @chunky.palette.grayscale?
          raw = @chunky.to_grayscale_stream
        else
          raw = @chunky.to_rgb_stream
        end
        Zlib::Deflate.deflate(raw)
      end

      def extract_alpha_channel
        raw = @chunky.to_alpha_channel_stream

        if raw.match(/\A\xFF+\Z/)
          nil
        else
          Zlib::Deflate.deflate(raw)
        end
      end
    end
  end
end
