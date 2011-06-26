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
        @ds     = ChunkyPNG::Datastream.from_blob(data)
        @width  = @chunky.width
        @height = @chunky.height
        @bits   = extract_bits

        case color_type
        when 0,2,3
          @img_data      = filtered_image_data
          @alpha_channel = nil
        when 4,6
          @img_data      = unfiltered_image_data
          @alpha_channel = unfiltered_alpha_channel
        else
          raise Errors::UnsupportedImageType, "Unsupported PNG color type #{@color_type}"
        end
      end

      def alpha_channel?
        @alpha_channel != nil
      end

      def no_alpha_channel?
        @alpha_channel.nil?
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
          :ColorSpace       => colorspace(document)
        )

        # append the actual image data to the object as a stream
        obj << @img_data

        # add in any transparent mask data we have
        obj.data[:Mask] = mask if mask

        if alpha_channel?
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
        else
          obj.data[:DecodeParms] = {:Predictor => 15,
                                    :Colors    => self.colors,
                                    :BitsPerComponent => self.bits,
                                    :Columns   => self.width}
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

      # number of color components to each pixel
      #
      def colors
        case self.color_type
        when 0, 3, 4
          return 1
        when 2, 6
          return 3
        end
      end

      # return the PNG color type of this image
      #
      def color_type
        @color_type ||= @ds.header_chunk.color
      end


      def colorspace(document)
        @colorspace ||= if @ds.palette_chunk
                          chunk = @ds.palette_chunk
                          palette_obj = document.ref!(:Length => chunk.content.size)
                          palette_obj << chunk.content
                          [:Indexed, :DeviceRGB, (chunk.content.size / 3) -1, palette_obj]
                        elsif colors == 1
                          :DeviceGray
                        else
                          :DeviceRGB
                        end
      end

      private

      def mask
        return nil if @ds.transparency_chunk.nil?

        @mask ||= case self.color_type
                  when 0 then
                    val = @ds.transparency_chunk.content.unpack("n").first
                    [val, val]
                  when 3 then
                    array = @ds.transparency_chunk.content.unpack("C*")
                    array << 255 while array.size < 255
                    #  array << 255
                    #end
                    array.map { |val| [ val, val ] }
                  else
                    nil
                  end
      end

      def extract_bits
        bits ||= @ds.header_chunk.depth
        bits = 8 if bits > 8
        bits
      end

      # unfilters the compressed PNG data and extracts raw pixel data WITHOUT
      # the alpha channel.
      #
      # This is expensive, only do it on PNG types 4 and 6 where we have no
      # option but to split out the alpha channel.
      #
      def unfiltered_image_data
        if @chunky.palette.grayscale?
          raw = @chunky.to_grayscale_stream
        else
          raw = @chunky.to_rgb_stream
        end
        Zlib::Deflate.deflate(raw)
      end

      # unfilters the compressed PNG data and extracts raw alpha channel WITHOUT
      # the color data. There will always be 1 byte per pixel.
      #
      # This is expensive, only do it on PNG types 4 and 6 where we have no
      # option but to split out the alpha channel.
      #
      def unfiltered_alpha_channel
        raw = @chunky.to_alpha_channel_stream

        if raw.match(/\A\xFF+\Z/)
          nil
        else
          Zlib::Deflate.deflate(raw)
        end
      end

      # return the compressed pixel data from the unerlying image. The data is
      # pre-processed with the PNG predictors then compressed with zlib.
      #
      # If the image has no alpha channel (color type 1, 2 and 3) then there is
      # no need to perform the expensive unfiltering operations. It can be
      # embedded as is.
      #
      def filtered_image_data
        @ds.data_chunks.map { |c| c.content }.join('')
      end
    end
  end
end
