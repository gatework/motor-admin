# frozen_string_literal: true

require 'test_helper'

class MiniMimeTest < ActiveSupport::TestCase
  test 'looks up multiple mime types through cached database' do
    assert_equal 'text/plain', MiniMime.lookup_by_filename('readme.txt').content_type
    assert_equal 'image/png', MiniMime.lookup_by_filename('image.png').content_type
  end
end
