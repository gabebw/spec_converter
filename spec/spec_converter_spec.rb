require 'spec_helper'

describe SpecConverter, ".start" do
  it "creates an instance and calls convert" do
    converter = stub
    SpecConverter.expects(:new).returns(converter)
    converter.expects(:convert)
    SpecConverter.start
  end
end

describe SpecConverter, "#translate_file" do
  it "converts in-place" do
    file = Tempfile.open("some_file.rb")
    file << "Here is some stuff that is cool!"
    file.close

    converter = SpecConverter.new
    converter.expects(:convert_line).with(anything).returns("Translated to be super awesome")
    converter.translate_file(file.path)

    File.open(file.path).read.should == "Translated to be super awesome"
  end
end

describe SpecConverter, "#convert" do
  let(:converter){ SpecConverter.new }

  it "converts all test files in the test subdirectory in batch" do
    converter.expects(:convert_line).never
    files = %w[test/foo_test.rb test/models/another_test.rb]
    files.each do |file|
      converter.expects(:translate_file).with(file)
    end
    Dir.expects(:glob).with(anything()).returns(files)
    File.stubs(:directory?).with("test").returns(true)
    converter.convert
  end
end

describe SpecConverter, "#convert_def_setup" do
  let(:converter){ SpecConverter.new }
  it "replaces 'setup' with 'before'" do
    converter.convert_def_setup(%[def setup\n]).should == %[before do\n]
  end

  it "ignores method definitions that only start with setup" do
    converter.convert_def_setup(%[def setup_my_object]).should == %[def setup_my_object]
  end
end

describe SpecConverter, "#convert_rspec_old_style_names" do
  let(:converter){ SpecConverter.new }

  it "does not replace context with describe" do
    line = %[context "should foo bar" do]
    whitespace = " " * 3
    converter.convert_rspec_old_style_names(line).should == line
    converter.convert_rspec_old_style_names(whitespace + line).should == (whitespace + line)
  end

  it "replaces 'specify' with 'it'" do
    converter.convert_rspec_old_style_names(%[specify "remember me saves the user" do]).should == %[it "remember me saves the user" do]
  end

  it "ignores unrelated uses of 'specify'" do
    comment = %[# I like to specify things]
    user_should = %[@user.should.specify.stuff]
    converter.convert_rspec_old_style_names(comment).should == comment
    converter.convert_rspec_old_style_names(user_should).should == user_should
  end
end

describe SpecConverter, "#convert_test_unit_class_name" do
  let(:converter){ SpecConverter.new }

  it "replaces ActionController::IntegrationTest with a describe block" do
    converter.convert_test_unit_class_name(%[class ResearchTest < ActionController::IntegrationTest]).should == %[describe Research do]
  end

  it "replaces ActionController::TestCase with a describe block" do
    converter.convert_test_unit_class_name(%[class ResearchControllerTest < ActionController::TestCase]).should == %[describe ResearchController do]
  end

  it "replaces ActiveSupport::TestCase with a describe block" do
    converter.convert_test_unit_class_name(%[class ResearchControllerTest < ActiveSupport::TestCase]).should == %[describe ResearchController do]
  end

  it "replaces Test::Unit::TestCase with a describe block" do
    converter.convert_test_unit_class_name(%[class ResearchTest < Test::Unit::TestCase]).should == %[describe Research do]
    converter.convert_test_unit_class_name(%[class ResearchTest       < Test::Unit::TestCase]).should == %[describe Research do]
  end

  it "converts namespaced Test::Unit classes" do
    converter.convert_test_unit_class_name(%[class Admin::DashboardControllerTest < Test::Unit::TestCase]).should == %[describe Admin::DashboardController do]
  end

  it "ignores unrelated classes" do
    converter.convert_test_unit_class_name(%[class Foo]).should == %[class Foo]
    converter.convert_test_unit_class_name(%[class Bar < ActiveRecord::Base]).should == %[class Bar < ActiveRecord::Base]
  end
end

describe SpecConverter, "#convert_test_unit_methods" do
  let(:converter){ SpecConverter.new }
  it "replaces a 'test_something?' method with an it block" do
    converter.convert_test_unit_methods(%[def test_something?]).should == %[it "something?" do]
  end

  it "replaces a 'test_something' method with an it block" do
    converter.convert_test_unit_methods(%[def test_something]).should == %[it "something" do]
  end

  it "ignores unrelated lines" do
    converter.convert_test_unit_methods(%[def foo]).should == %[def foo]
  end
end

describe SpecConverter, "#convert_dust_style" do
  let(:converter){ SpecConverter.new }

  it "changes a test block to an it block" do
    converter.convert_dust_style(%[test "should do something cool and fun!!" do]).should == %[it "should do something cool and fun!!" do]
  end

  it "ignores unrelated dust_styles" do
    converter.convert_dust_style(%[# test that this class can do something right]).should == %[# test that this class can do something right]
  end
end

describe SpecConverter, "#convert_assert" do
  let(:converter){ SpecConverter.new }

  it "replaces 'assert !foo' with 'foo.should_not be'" do
    converter.convert_assert(%[assert !foo]).should == %[foo.should_not be]
  end

  it "converts foo.question? without args to be_question" do
    converter.convert_assert(%[assert !subscription.question?]).should == %[subscription.should_not be_question]
    converter.convert_assert(%[assert subscription.question?]).should == %[subscription.should be_question]
  end

  it "converts foo.question? with args to a version that preserves args" do
    converter.convert_assert(%[assert !subscription.question?(one)]).should ==
      %[subscription.question?(one).should_not be]
    converter.convert_assert(%[assert subscription.question?(one)]).should ==
      %[subscription.question?(one).should be]
  end

  it "replaces assert_equal with 'should =='" do
    converter.convert_assert(%[assert_equal "$1,490.00", x["price"]\n]).should == %[x["price"].should == "$1,490.00"\n]
  end

  it "replaces assert_not_equal with 'should_not =='" do
    converter.convert_assert(%[assert_not_equal "$1,490.00", x["price"]\n]).should == %[x["price"].should_not == "$1,490.00"\n]
  end

  it "keeps messages" do
    converter.convert_assert(%[assert_equal "$1,490.00", x["price"], "my message here"\n]).should == %[x["price"].should == "$1,490.00", "my message here"\n]
  end

  it "replaces assert with 'should be'" do
    converter.convert_assert(%[assert foo]).should == %[foo.should be]
  end

  it "replaces assert_nil with 'should be_nil'" do
    converter.convert_assert(%[assert_nil foo]).should == %[foo.should be_nil]
  end

  it "replaces assert_true with 'should be_true" do
    converter.convert_assert(%[assert_true foo]).should == %[foo.should be_true]
  end

  it "replaces assert_false with 'should be_false'" do
    converter.convert_assert(%[assert_false foo]).should == %[foo.should be_false]
  end

  it "replaces assert_not_nil with 'should_not be_nil" do
    converter.convert_assert(%[assert_not_nil foo]).should == %[foo.should_not be_nil]
  end

  it "replaces 'assert foo > 20' with 'foo.should > 20'" do
    converter.convert_assert(%[assert foo > 20]).should == %[foo.should > 20]
  end

  it "replaces assert_kind_of with 'should be_a_kind_of'" do
    converter.convert_assert(%[assert_kind_of Hash, foo, "No options given"]).should == %[foo.should be_a_kind_of Hash, "No options given"]
  end

  it "replaces assert_valid with 'should be_valid'" do
    converter.convert_assert(%[assert_valid @subscription]).should == %[@subscription.should be_valid]
  end

  it "replaces assert_in_delta with 'should be_within'" do
    converter.convert_assert(%[assert_in_delta @time.created_at, @time.ends_at, 1.minute]).should == %[@time.ends_at.should be_within(1.minute).of(@time.created_at)]
  end
end

describe SpecConverter, "#convert_line" do
  let(:converter){ SpecConverter.new }

  it "exists" do
    converter.should respond_to :convert_line
  end
end

describe SpecConverter, "#convert_shoulda_active_record" do
  let(:converter){ SpecConverter.new }

  %w{allow_value
     ensure_length_of
     ensure_inclusion_of
     validate_presence_of
     validate_format_of
     validate_uniqueness_of
     validate_acceptance_of
     validate_numericality_of
     belong_to
     have_many
     have_one
     have_and_belong_to_many
     have_db_column
     have_db_index
     have_readonly_attribute
     allow_mass_assignment_of}.each do |ar_matcher|
       it "converts #{ar_matcher}" do
         result = converter.convert_shoulda_active_record("should #{ar_matcher}(:blerg).with('hello')")
         result.should == "it { should #{ar_matcher}(:blerg).with('hello') }"
       end
     end
end

describe SpecConverter, "#convert_shoulda_setup" do
  let(:converter){ SpecConverter.new }

  it "converts an inline setup block to a before block" do
    result = converter.convert_shoulda_setup("setup { @user = User.new(:name => 'John') }")
    result.should == "before { @user = User.new(:name => 'John') }"
  end

  it "converts a multiline setup block using braces to a before block" do
    result = converter.convert_shoulda_setup("setup {")
    result.should == "before {"
  end

  it "converts a multiline setup block using do...end to a before block" do
    result = converter.convert_shoulda_setup("setup do")
    result.should == "before do"
  end
end

describe SpecConverter, "#convert_shoulda_block" do
  let(:converter){ SpecConverter.new }

  it "converts shoulda blocks to it blocks" do
    result = converter.convert_shoulda_block(%q{should "create a record" do})
    result.should == %q{it "should create a record" do}
  end

  it "handles single-quoted descriptions" do
    result = converter.convert_shoulda_block(%q{should 'create "a" record' do})
    result.should == %q{it 'should create "a" record' do}
  end

  it "ignores ActiveRecord matchers" do
    input = "should validate_presence_of(:name)"
    converter.convert_shoulda_block(input).should == input
  end
end
