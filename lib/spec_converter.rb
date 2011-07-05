# Simple converter to go to test/spec style
# This will change all files in place, so make sure you are properly backed up and/or committed to SVN!
class SpecConverter
  VERSION = "0.0.4"

  def self.start
    spec_converter = SpecConverter.new
    spec_converter.convert
  end

  # Convert tests from old spec style to new style -- assumes you are in your project root and globs all tests
  # in your test directory.
  def convert
    raise "No test diretory - you must run this script from your project root, which should also contain a test directory." unless File.directory?("test")
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
    convert_rspec_old_style_names(line)
    convert_dust_style(line)
    convert_test_unit_class_name(line)
    convert_test_unit_methods(line)
    convert_def_setup(line)
    convert_assert(line)
    line
  end

  private

  def convert_def_setup(line)
    line.gsub!(/(^\s*)def setup(\s*)$/, '\1before do\2')
  end

  def convert_rspec_old_style_names(line)
    line.gsub!(/(^\s*)specify(\s.*do)/, '\1it\2')
  end

  def convert_test_unit_class_name(line)
    line.gsub!(/^class\s*([\w:]+)Test\s*<\s*Test::Unit::TestCase/, 'describe \1 do')
    line.gsub!(/^class\s*([\w:]+)Test\s*<\s*(ActiveSupport|ActionController)::(IntegrationTest|TestCase)/, 'describe \1 do')
  end

  def convert_test_unit_methods(line)
    line.gsub!(/(^\s*)def\s*test_([\w_!?,$]+)/) { %{#{$1}it "#{$2.split('_').join(' ')}" do} }
  end

  def convert_dust_style(line)
    line.gsub!(/(^\s*)test(\s.*do)/, '\1it\2')
  end

  def convert_assert(line)
    converted_line = line.dup
    leading_space = converted_line.slice!(/^\s*/)

    converted_line.gsub!(/assert\s+([^\s]*)\s*([<=>~]+)\s*(.*)$/,
                         '\1.should \2 \3' )
    converted_line.gsub!(/assert\s+\!(.*)$/, '\1.should_not be' )
    converted_line.gsub!(/assert_not_nil\s+(.*)$/, '\1.should_not be_nil' )
    converted_line.gsub!(/assert\s+(.*)$/, '\1.should be' )
    converted_line.gsub!(/assert_(nil|true|false)\s+(.*)$/,
                         '\2.should be_\1' )
    converted_line.gsub!(/assert_equal\s+("[^"]+"|[^,]+),\s*("[^"]+"|[^,\n]+)(,\s*(?:['"]|%[Qq]).+)?$/,
                         '\2.should == \1\3' )
    line.replace(leading_space + converted_line)
  end
end
