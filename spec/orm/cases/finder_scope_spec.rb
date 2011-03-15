require 'spec_helper'
require 'orm/models/person'

describe MassiveRecord::ORM::Finders::Scope do
  let(:subject) { MassiveRecord::ORM::Finders::Scope.new(nil) }

  MassiveRecord::ORM::Finders::Scope::MULTI_VALUE_METHODS.each do |multi_values|
    it "should have #{multi_values} as an empty array as default" do
      subject.send(multi_values+"_values").should == []
    end
  end

  MassiveRecord::ORM::Finders::Scope::SINGLE_VALUE_METHODS.each do |singel_value|
    it "should have #{singel_value} as nil as default" do
      subject.send(singel_value+"_value").should be_nil
    end
  end


  describe "scoping methods" do
    (MassiveRecord::ORM::Finders::Scope::MULTI_VALUE_METHODS + MassiveRecord::ORM::Finders::Scope::SINGLE_VALUE_METHODS).each do |method|
      it { should respond_to(method) }

      it "should return self after #{method}()" do
        subject.send(method, nil).should == subject
      end
    end



    describe "multi value methods" do
      describe "select" do
        it "should not add nil values" do
          subject.select(nil)
          subject.select_values.should be_empty
        end

        it "should add incomming value to list" do
          subject.select(:info)
          subject.select_values.should include 'info'
        end

        it "should be adding values if called twice" do
          subject.select(:info).select(:base)
          subject.select_values.should include 'info', 'base'
        end

        it "should add multiple arguments" do
          subject.select(:info, :base)
          subject.select_values.should include 'info', 'base'
        end

        it "should add multiple values given as array" do
          subject.select([:info, :base])
          subject.select_values.should include 'info', 'base'
        end

        it "should not add same value twice" do
          subject.select(:info).select('info')
          subject.select_values.should == ['info']
        end
      end
    end



    describe "singel value methods" do
      describe "limit" do
        it "should set a limit" do
          subject.limit(5)
          subject.limit_value.should == 5
        end

        it "should be set to the last value set" do
          subject.limit(1).limit(5)
          subject.limit_value.should == 5
        end
      end
    end
  end


  describe "#find_options" do
    it "should return an empty hash when no limitations are set" do
      subject.send(:find_options).should == {}
    end

    it "should include a limit if asked to be limited" do
      subject.limit(5).send(:find_options).should include :limit => 5
    end

    it "should include selection when asked for it" do
      subject.select(:info).send(:find_options).should include :select => ['info']
    end
  end


  describe "loaded" do
    it { should_not be_loaded }

    it "should be loaded if set to true" do
       subject.loaded = true
       should be_loaded
    end
  end


  describe "#reset" do
    it "should reset loaded status" do
      subject.loaded = true
      subject.reset
      should_not be_loaded
    end
  end

  describe "#to_a" do
    it "should return @records if loaded" do
      records = [:foo]
      subject.instance_variable_set(:@records, records)
      subject.loaded = true

      subject.to_a.should == records
    end


    [:to_xml, :to_yaml, :length, :collect, :map, :each, :all?, :include?].each do |method|
      it "should delegate #{method} to to_a" do
        records = mock(Array)
        records.should_receive(method)

        subject.instance_variable_set(:@records, records)
        subject.loaded = true

        subject.send(method)
      end
    end
  end


  describe "#first" do
    it "should return first record if loaded" do
      records = mock(Array)
      records.should_receive(:first).and_return(:first_record)
      subject.instance_variable_set(:@records, records)
      subject.loaded = true

      subject.first.should == :first_record
    end

    it "should include finder options" do
      extra_options = {:foo => :bar}

      klass = mock(Object)
      klass.should_receive(:find).with(anything, hash_including(extra_options)).and_return([])
      subject.should_receive(:klass).and_return(klass)

      subject.first(extra_options)
    end
  end

  describe "#all" do
    it "should simply call to_a" do
      subject.should_receive(:to_a).and_return []
      subject.all
    end


    it "should include finder options" do
      extra_options = {:foo => :bar}

      klass = mock(Object)
      klass.should_receive(:find).with(anything, extra_options)
      subject.should_receive(:klass).and_return(klass)

      subject.all(extra_options)
    end
  end


  describe "#==" do
    it "should be counted equal if it's records are the same as asked what being compared to" do
      subject.instance_variable_set(:@records, [:foo])
      subject.loaded = true

      subject.==([:foo]).should == true
    end
  end



  describe "real world test" do
    include SetUpHbaseConnectionBeforeAll
    include SetTableNamesToTestTable

    describe "with a person" do
      let(:person_1) { Person.create! :id => "ID1", :name => "Person1", :email => "one@person.com", :age => 11, :points => 111, :status => true }
      let(:person_2) { Person.create! :id => "ID2", :name => "Person2", :email => "two@person.com", :age => 22, :points => 222, :status => false }

      before do
        person_1.save!
        person_2.save!
      end

      (MassiveRecord::ORM::Finders::Scope::MULTI_VALUE_METHODS + MassiveRecord::ORM::Finders::Scope::SINGLE_VALUE_METHODS).each do |method|
        it "should not load from database when Person.#{method}() is called" do
          Person.should_not_receive(:find)
          Person.send(method, 5)
        end
      end

      it "should find just one record when asked for it" do
        Person.limit(1).should == [person_1]
      end
    end
  end
end
