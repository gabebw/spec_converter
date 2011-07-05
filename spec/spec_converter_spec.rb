require 'spec_helper'

describe SpecConverter, ".start" do
  it "creates an instance and calls convert" do
    SpecConverter.expects(:new).returns(converter = stub)
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

describe SpecConverter, "#convert_line" do
  let(:converter){ SpecConverter.new }

  context "when converting from old RSpec names to new names" do
    it "does not replace context with describe" do
      line = %[context "should foo bar" do]
      whitespace = " " * 3
      converter.convert_line(line).should == line
      converter.convert_line(whitespace + line).should == (whitespace + line)
    end

    it "ignores unrelated uses of 'context'" do
      comment   = %[# here is a comment with context]
      iteration = %[contexts.each do |context|]
      converter.convert_line(comment).should == comment
      converter.convert_line(iteration).should == iteration
    end

    it "replaces 'specify' with 'it'" do
      converter.convert_line(%[    specify "remember me saves the user" do]).should == %[    it "remember me saves the user" do]
    end

    it "ignores unrelated uses of 'specify'" do
      comment = %[# I like to specify things]
      user_should = %[  @user.should.specify.stuff]
      converter.convert_line(comment).should == comment
      converter.convert_line(user_should).should == user_should
    end
  end

  context "converting dust style to test/spec style" do
    it "changes a test block to an it block" do
      converter.convert_line(%[test "should do something cool and fun!!" do]).should == %[it "should do something cool and fun!!" do]
    end

    it "ignores unrelated lines" do
      converter.convert_line(%[# test that this class can do something right]).should == %[# test that this class can do something right]
    end
  end

  context "converting ActionController tests to describe blocks" do
    it "replaces ActionController::IntegrationTest with a describe block" do
      converter.convert_line(%[class ResearchTest < ActionController::IntegrationTest]).should == %[describe Research do]
    end

    it "replaces ActionController::TestCase with a describe block" do
      converter.convert_line(%[class ResearchControllerTest < ActionController::TestCase]).should == %[describe ResearchController do]
    end

    it "replaces ActiveSupport::TestCase with a describe block" do
      converter.convert_line(%[class ResearchControllerTest < ActiveSupport::TestCase]).should == %[describe ResearchController do]
    end
  end

  context "converting Test::Unit style to describe blocks" do
    it "replaces Test::Unit::TestCase with a describe block" do
      converter.convert_line(%[class ResearchTest < Test::Unit::TestCase]).should == %[describe Research do]
      converter.convert_line(%[class ResearchTest       < Test::Unit::TestCase]).should == %[describe Research do]
    end

    it "converts namespaced Test::Unit classes" do
      converter.convert_line(%[class Admin::DashboardControllerTest < Test::Unit::TestCase]).should == %[describe Admin::DashboardController do]
    end

    it "ignores unrelated classes" do
      converter.convert_line(%[class Foo]).should == %[class Foo]
      converter.convert_line(%[class Bar < ActiveRecord::Base]).should == %[class Bar < ActiveRecord::Base]
    end
  end

  context "converting Test::Unit methods to it blocks" do
    it "replaces 'setup' with 'before'" do
      converter.convert_line(%[def setup\n]).should == %[before do\n]
    end

    it "ignores method definitions that only start with setup" do
      converter.convert_line(%[def setup_my_object]).should == %[def setup_my_object]
    end

    it "replaces a 'test_something?' method with an it block" do
      converter.convert_line(%[def test_something?]).should == %[it "something?" do]
    end

    it "replaces a 'test_something' method with an it block" do
      converter.convert_line(%[def test_something]).should == %[it "something" do]
    end

    it "replaces a 'test_something' method with an it block even with leading whitespace" do
      space = ' ' * 3
      converter.convert_line(space + %[def test_something_here]).should == (space + %[it "something here" do])
    end

    it "ignores unrelated lines" do
      converter.convert_line(%[def foo]).should == %[def foo]
    end

    it "ignores unrelated lines with leading whitespace" do
      converter.convert_line(%[   def foo]).should == %[   def foo]
    end
  end

  context "converting assertions" do
    it "replaces 'assert !foo' with 'foo.should_not be'" do
      converter.convert_line(%[assert !foo]).should == %[foo.should_not be]
    end

    it "replaces assert_equal with 'should =='" do
      converter.convert_line(%[assert_equal "$1,490.00", x["price"]\n]).should == %[x["price"].should == "$1,490.00"\n]
    end

    it "keeps messages" do
      converter.convert_line(%[assert_equal "$1,490.00", x["price"], "my message here"\n]).should == %[x["price"].should == "$1,490.00", "my message here"\n]
    end

    it "replaces assert with 'should be'" do
      converter.convert_line(%[assert foo]).should == %[foo.should be]
    end

    it "replaces assert_nil with 'should be_nil'" do
      converter.convert_line(%[assert_nil foo]).should == %[foo.should be_nil]
    end

    it "replaces assert_true with 'should be_true" do
      converter.convert_line(%[assert_true foo]).should == %[foo.should be_true]
    end

    it "replaces assert_false with 'should be_false'" do
      converter.convert_line(%[assert_false foo]).should == %[foo.should be_false]
    end

    it "replaces assert_not_nil with 'should_not be_nil" do
      converter.convert_line(%[assert_not_nil foo]).should == %[foo.should_not be_nil]
    end
    it "replaces 'assert foo > 20' with 'foo.should > 20'" do
      converter.convert_line(%[assert foo > 20]).should == %[foo.should > 20]
    end
  end
end
