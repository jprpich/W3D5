require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        cats
      SQL
    @columns = cols.first.map { |col| col.to_sym }
  end

  def self.finalize!
      self.columns.each do |column|
        define_method(column) do 
          # debugger
          self.attributes[column]  
        end

        define_method("#{column}=") do |val| 
          # debugger
          self.attributes[column] = val
        end

      end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    cols = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      SQL
    self.parse_all(cols)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE 
        id = #{id}
      SQL
    parse_all(obj).first
  end

  def initialize(params = {})
    params.each do |key, val|
      if self.class.columns.include?(key.to_sym)
        key = key.to_sym 
        self.send("#{key}=", val)
      else
        raise "unknown attribute '#{key}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values 
    # debugger
  end

  def insert
    columns = self.class.columns[1..-1]
    # debugger
    p columns 
    col_names = columns.map(&:to_s).join(", ")
    # debugger
    p col_names
    question_marks = Array.new(columns.count-1, "?").join(",")
    # debugger
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
  end

  def save
    # ...
  end
end

# @columns just holds column names
# @attributes holds key, value pairs where key is column and value is 
# that instances attribute 
# the instance is a row 

# deconstruct my attributes as well as my column names
# reformat them into a sql string 
# execute the sql insertion to put me in the db