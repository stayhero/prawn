# encoding: ASCII-8BIT

# Spec'ing the PNG class. Not complete yet - still needs to check the
# contents of palette and transparency to ensure they're correct.
# Need to find files that have these sections first.
#
# see http://www.w3.org/TR/PNG/ for a detailed description of the PNG spec,
# particuarly Table 11.1 for the different color types

require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")

describe "When reading a greyscale PNG file (color type 0)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/web-links.png"
    @data_filename = "#{Prawn::DATADIR}/images/web-links.dat"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 21
    png.height.should == 14
    png.bits.should == 8
    png.color_type.should == 0
  end

  it "should extract the raw image data with exactly 1 byte per pixel + 1 byte per row" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 308
  end

  it "should read the image data chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)
    data = Zlib::Inflate.inflate(File.binread(@data_filename))
    png.img_data.should == data
  end

  it "should have no alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == false
  end
end

describe "When reading a greyscale PNG file with transparency (color type 0)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/ruport_type0.png"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 258
    png.height.should == 105
    png.bits.should == 8
    png.color_type.should == 0
  end

  it "should extract the raw image data with exactly 1 byte per pixel plus 1 byte per row" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 27195
  end

  it "should have no alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == false
  end

end

describe "When reading an RGB PNG file (color type 2)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/ruport.png"
    @data_filename = "#{Prawn::DATADIR}/images/ruport_data.dat"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 258
    png.height.should == 105
    png.bits.should == 8
    png.color_type.should == 2
  end

  it "should extract the raw image data with exactly 3 bytes per pixel plus 1 byte per row" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 81375
  end

  it "should read the image data chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)
    data = Zlib::Inflate.inflate(File.binread(@data_filename))
    png.img_data.should == data
  end

  it "should have no alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == false
  end
end

describe "When reading an RGB PNG file with transparency (color type 2)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/arrow2.png"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 6
    png.height.should == 10
    png.bits.should == 8
    png.color_type.should == 2
  end

  it "should extract the raw image data with exactly 3 bytes per pixel plus 1 byte per row" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 190
  end

  it "should have no alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == false
  end

end

describe "When reading an indexed color PNG file (color type 3)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/indexed_color.png"
    @data_filename = "#{Prawn::DATADIR}/images/indexed_color.dat"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 150
    png.height.should == 200
    png.bits.should == 8
    png.color_type.should == 3
  end

  it "should extract the raw image data with exactly 1 byte per pixel plus 1 byte per row" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 3264
  end

  it "should read the image data chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)
    data = Zlib::Inflate.inflate(File.binread(@data_filename))
    png.img_data.should == data
  end

  it "should have no alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == false
  end
end

describe "When reading a greyscale+alpha PNG file (color type 4)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/page_white_text.png"
    @data_filename = "#{Prawn::DATADIR}/images/page_white_text.dat"
    @alpha_data_filename = "#{Prawn::DATADIR}/images/page_white_text.alpha"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 16
    png.height.should == 16
    png.bits.should == 8
    png.color_type.should == 4
  end

  it "should extract the raw image data with exactly 1 byte per pixel" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 256
  end

  it "should correctly return the raw image data (with no alpha channel) from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@data_filename)
    png.img_data.should == data
  end

  it "should have an alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == true
  end

  it "should extract the raw alpha channel with exactly 1 byte per pixel" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.alpha_channel).bytesize.should == 256
  end

  it "should correctly extract the alpha channel data from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@alpha_data_filename)
    png.alpha_channel.should == data
  end
end

describe "When reading an RGB+alpha PNG file (color type 6)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/dice.png"
    @data_filename = "#{Prawn::DATADIR}/images/dice.dat"
    @alpha_data_filename = "#{Prawn::DATADIR}/images/dice.alpha"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 320
    png.height.should == 240
    png.bits.should == 8
    png.color_type.should == 6
  end

  it "should extract the raw image data with exactly 3 bytes per pixel" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.img_data).bytesize.should == 230400
  end

  it "should correctly return the raw image data (with no alpha channel) from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@data_filename)
    png.img_data.should == data
  end

  it "should have an alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == true
  end

  it "should extract the raw alpha channel with exactly 1 byte per pixel" do
    png = Prawn::Images::PNG.new(@img_data)
    Zlib::Inflate.new.inflate(png.alpha_channel).bytesize.should == 76800
  end

  it "should correctly extract the alpha channel data from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@alpha_data_filename)
    png.alpha_channel.should == data
  end
end

describe "When reading a 16bit RGB+alpha PNG file (color type 6)" do

  before(:each) do
    @filename = "#{Prawn::DATADIR}/images/16bit.png"
    @data_filename = "#{Prawn::DATADIR}/images/16bit.dat"
    # alpha channel truncated to 8-bit
    @alpha_data_filename = "#{Prawn::DATADIR}/images/16bit.alpha"
    @img_data = File.binread(@filename)
  end

  it "should read the attributes from the header chunk correctly" do
    png = Prawn::Images::PNG.new(@img_data)

    png.width.should == 32
    png.height.should == 32
    png.bits.should == 16
    png.color_type.should == 6
  end

  it "should correctly return the raw image data (with no alpha channel) from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@data_filename)
    png.img_data.should == data
  end

  it "should have an alpha channel" do
    png = Prawn::Images::PNG.new(@img_data)
    png.alpha_channel?.should == true
  end

  it "should correctly extract the alpha channel data from the image data chunk" do
    png = Prawn::Images::PNG.new(@img_data)
    data = File.binread(@alpha_data_filename)
    png.alpha_channel.should == data
  end
end
