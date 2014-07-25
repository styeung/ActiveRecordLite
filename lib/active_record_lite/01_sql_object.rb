require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject

  def self.columns
    output = DBConnection::execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    columns = output.first
    columns.map do |column|
      column.to_sym
    end

  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |value|
        self.attributes[column] = value
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
    query = DBConnection.execute(<<-SQL)
      SELECT
      #{self.table_name}.*
      FROM
      #{self.table_name}
    SQL
    self.parse_all(query)
  end

  def self.parse_all(results)
    output = []
    results.each do |hash|
      output << self.new(hash)
    end

    output
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
    SELECT
    #{self.table_name}.*
    FROM
    #{self.table_name}
    WHERE
    #{self.table_name}.id = #{id}
    SQL

    self.new(result.first)
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(",")
    question_marks = ["?"]*cols.length
    question_marks = question_marks.join(",")

    values = self.attribute_values

    DBConnection.execute(<<-SQL, *values)
    INSERT INTO
    #{self.class.table_name} (#{col_names})
    VALUES
    (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    params.each_key do |key|
      raise Exception.new("unknown attribute #{key}") unless self.class.columns.include?(key.to_sym)
    end

    params.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end


  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    cols = self.class.columns
    values = self.attribute_values

    cols = cols.map do |x|
      "#{x} = ?"
    end.join(",")

    p cols

    DBConnection.execute(<<-SQL, *values)
    UPDATE
      #{self.class.table_name}
    SET
      #{cols}
    WHERE
      id = #{self.id}
    SQL


  end

  def attribute_values
    self.class.columns.map do |x|
      self.send(x.to_s)
    end
  end
end
