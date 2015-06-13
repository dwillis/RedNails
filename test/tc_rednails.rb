# $Id: tc_scrapper.rb 319 2005-12-06 05:51:40Z zb $
#
# Test cases for the Scrapper
#
# Copyright (c) 2004-2005 Ubiquitous Business Technology, Inc.
#
# Authors: Zev Blut

require 'minitest/autorun'
require "rednails"

RN_PATH = File.dirname(__FILE__)

class TC_RedNails < Minitest::Test

  def read_file(file)
    File.open(file,"r") { |f| f.read }
  end

  def test_basic_template
    stemplate = RedNails.new("#{RN_PATH}/templatefile.html")
    test_text = read_file("#{RN_PATH}/templatefiletest.html")
    arr = stemplate.parse(test_text)
    assert_equal(["Header muck meader","Test Nug text","NUG2"],
                 arr,
                 "Extracted variables from template test file is not what was expected")
  end

  def test_rep_template
    stemplate = RedNails.new("#{RN_PATH}/reptemplate.html")
    test_text = read_file("#{RN_PATH}/reptemplatetest.html")
    arr = stemplate.parse(test_text)
    assert_equal([[
                     ["nug1.jpg", "nug1"], ["nug2.jpg", "nug2"],
                     ["nug3.jpg", "nug3"], ["nug4.jpg", "nug4"],
                     ["nug5.jpg", "nug5"] ]],
                 arr,
                 "Extracted variables from template test file is not what was expected")

    hash = stemplate.parse_hash(test_text)
    assert_equal({ "url_1" => "nug1.jpg", "txt_1" => "nug1",
                   "url_2" => "nug2.jpg", "txt_2" => "nug2",
                   "url_3" => "nug3.jpg", "txt_3" => "nug3",
                   "url_4" => "nug4.jpg", "txt_4" => "nug4",
                   "url_5" => "nug5.jpg", "txt_5" => "nug5" },
                 hash,
                 "Extracted variable hash from template test file is not what was expected")
  end

end
