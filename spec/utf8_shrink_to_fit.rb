# encoding: utf-8
require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")

describe "#shrink_to_fit with special utf-8 text" do
  it "Should not throw an exception" do
    pages = 0
    doc = Prawn::Document.new(page_size: 'A4', margin: [2, 2, 2, 2]) do |pdf|
      add_unicode_fonts(pdf)
      pdf.bounding_box([1, 1], :width => 90, :height => 50) do
        broken_text = " Sample Text\nSAMPLE SAMPLE SAMPLEoddělení ZMĚN\nSAMPLE"
        pdf.text broken_text, :overflow => :shrink_to_fit
      end
    end
  end
end


def add_unicode_fonts(pdf)
  dejavu = "#{::Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
  pdf.font_families.update("dejavu" => {
    :normal      => dejavu,
    :italic      => dejavu,
    :bold        => dejavu,
    :bold_italic => dejavu
  })
  pdf.fallback_fonts = ["dejavu"]
end