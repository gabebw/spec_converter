# Simple converter to go to test/spec style
# This will change all files in place, so make sure you are properly backed up and/or committed to SVN!

require 'shoulda/matchers/active_record'

class SpecConverter
  VERSION = "0.5.3"

  RE_SHOULDA_ACTIVE_RECORD = /#{Shoulda::Matchers::ActiveRecord.instance_methods.map{|m| m.to_s}.join('|')}/o

  def self.start
    spec_converter = SpecConverter.new
    spec_converter.convert
  end

  # Convert tests from old spec style to new style -- assumes you are in your project root and globs all tests
  # in your test directory.
  def convert
    unless File.directory?("test")
      raise "No ./test directory! Must be run from project root, which must contain /test."
    end
    tests = Dir.glob('test/**/*_test.rb')
    tests.each do |test_file|
      translate_file(test_file)
    end
  end

  def translate_file(file)
    translation = ""
    File.open(file) do |io|
      io.each_line do |line|
        translation << convert_line(line)
      end
    end
    File.open(file, "w") do |io|
      io.write(translation)
    end
  end

  def convert_line(line)
    new_line = line.dup
    leading_space = new_line.slice!(/^\s*/)

    new_line = convert_rspec_old_style_names(new_line)
    new_line = convert_dust_style(new_line)
    new_line = convert_test_unit_class_name(new_line)
    new_line = convert_test_unit_methods(new_line)
    new_line = convert_def_setup(new_line)
    new_line = convert_assert(new_line)

    # Shoulda
    new_line = convert_shoulda_active_record(new_line)
    new_line = convert_shoulda_setup(new_line)

    leading_space + new_line
  end

  def convert_def_setup(line)
    line.gsub!(/^def setup(\s*)$/, 'before do\1')
    line
  end

  def convert_rspec_old_style_names(line)
    line.gsub!(/^specify(\s.*do)/, 'it\1')
    line
  end

  def convert_test_unit_class_name(line)
    line.gsub!(/^class\s*([\w:]+)Test\s*<\s*Test::Unit::TestCase/,
               'describe \1 do')
    line.gsub!(/^class\s*([\w:]+)Test\s*<\s*(ActiveSupport|ActionController)::(IntegrationTest|TestCase)/,
               'describe \1 do')

    line
  end

  def convert_test_unit_methods(line)
    line.gsub!(/^def\s*test_([\w_!?,$]+)/) do
      %{it "#{$1.split('_').join(' ')}" do}
    end

    line
  end

  def convert_dust_style(line)
    line.gsub!(/^test(\s.*do)/, 'it\1')
    line
  end

  def convert_assert(line)
    message_regex = /(,\s*(?:['"]|%[Qq]).+)?/

    line.gsub!(/^assert\s+([^\s]*)\s*([<=>~]+)\s*(.*)#{message_regex}$/,
               '\1.should \2 \3\4')

    line.gsub!(/^assert\s+([^!]+)\.([^\s]+)\?#{message_regex}?$/,
               '\1.should be_\2\3')

    line.gsub!(/^assert\s+!\s*([^!]+)\.([^\s]+)\?#{message_regex}?$/,
               '\1.should_not be_\2\3')


    line.gsub!(/^assert_not_nil\s+(.*)#{message_regex}$/,
               '\1.should_not be_nil\2')

    line.gsub!(/^assert_(nil|true|false|valid)\s+(.*)#{message_regex}$/,
               '\2.should be_\1\3' )

    line.gsub!(/^assert_equal\s+("[^"]+"|[^,]+),\s*("[^"]+"|[^,\n]+)#{message_regex}$/,
               '\2.should == \1\3')

    line.gsub!(/^assert_kind_of\s+([^\s]+),\s*([^,"]+)#{message_regex}$/,
               '\2.should be_a_kind_of \1\3' )

    line.gsub!(/^assert\s+([^!]*)#{message_regex}$/,
               '\1.should be\2' )

    line.gsub!(/^assert\s+\!(.*)#{message_regex}$/,
               '\1.should_not be\2' )

    line
  end

  def convert_shoulda_active_record(line)
    line.gsub!(/^(should #{RE_SHOULDA_ACTIVE_RECORD}.*)$/, 'it { \1 }')
    line
  end

  def convert_shoulda_setup(line)
    line.gsub!(/^setup (\{|do)/, 'before \1')
    line
  end
end
