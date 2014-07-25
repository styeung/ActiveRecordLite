require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    "#{self.class_name.downcase}s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each do |key, value|
      self.send("#{key}=", value)
    end

    self.foreign_key ||= "#{name}_id".to_sym
    self.primary_key ||= :id
    self.class_name ||= "#{name.to_s}".camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each do |key, value|
      self.send("#{key}=", value)
    end

    self.foreign_key ||= "#{self_class_name.downcase}_id".to_sym
    self.primary_key ||= :id
    self.class_name ||= "#{name.to_s.singularize}".camelcase
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name.to_sym) do
      result = DBConnection.execute(<<-SQL)
      SELECT
      *
      FROM
      #{options.table_name}
      WHERE
      id = #{self.send(options.foreign_key)}
      SQL
      object = options.model_class.constantize.new(result.first)
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.class, options)

    define_method(name.to_sym) do
      results = DBConnection.execute(<<-SQL)
      SELECT
      *
      FROM
      #{options.table_name}
      WHERE
      id = #{self.send(options.foreign_key)}
      SQL
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
