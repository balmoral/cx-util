# OpenTable is like an OpenStruct for tabular (row based) storage.
# It is intended to handle tables with many rows reasonably efficiently.
# It does this by storing columns as arrays, rather than rows as arrays.
# This also allows easy adding and dropping of columns, although it
# is less efficient for deleting rows (an action assumed to be less
# frequent).
#
# The 'attributes' of the table are columns. Columns of data can be
# accessed similarly to a Hash or OpenStruct.
#
# A table can be indexed by any column or combination of columns.
#
# Provide JSON and CSV output.
#
# EG
#   my_table[1]
#     will use standard array integer to return the second row of the table
#   my_table.where(:date).eq(today)
#     where(:date) returns a raw TableQuery.new(table, attr)
#   table_query.eq(value)
#     returns a cursor?
#   a cursor can take a block on construction
#   which will be iterated or
#   a cursor can be asked for rows
#   cursor.rows
#     will return all rows in the result each row as array
#   cursor.rows(:open, :high, :low, :close)
#     will return rows with specified attribute values
#   cursor.rows_json
#   cursor.rows_csv
#   cursor.rows_hash
#   cursor.rows_os
#   my_table.date_s(:date)
#     returns column (array) for :date attr
#   _s is way of saying you want all
#   my_table.where(condition)
#
# OpenTable#by(column_name)
#   returns an OpenTable::Index.new(table, column_name)

require 'json'

class Condition

  attr_reader :attr, :value, :gt, :lt, :eq
  attr_reader :and_condition, :or_condition

  def initialize(attr, value, gt, lt, eq)
    @attr = attr
    @value = value
    @gt, @lt, @eq = gt, lt, eq
    @and_condition = @or_condition = nil
  end

  def and(condition)
    if @and_condition || @or_condition
      (@and_condition || @or_condition).and(condition)
    else
      @and_condition = condition
      @or_condition = nil
    end
    self # to chain
  end

  def or(condition)
    if @and_condition || @or_condition
      (@and_condition || @or_condition).or(condition)
    else
      @or_condition = condition
      @and_condition = nil
    end
    self # to chain
  end

  def eval(target)
    result = false
    cmp = @value <=> target
    result = true if @gt && cmp == 1
    result = true if @lt && cmp == -1
    result = true if @eq && cmp == 0
    if @and_condition
      result &&= @and_condition.eval(target)
    elsif @or_condition
      result ||= @or_condition.eval(target)
    end
    result
  end

  def op_s
    s = "#{gt ? '>' : nil}#{lt ? '<' : nil}"
    if eq
      s.empty? ? '==' : "#{s}="
    else
      s
    end
  end

  def to_s
    unless @str
      @str = "#{attr} #{op_s} #{value}"
      @str = "#{@str} && #{@and_condition}" if @and_condition
      @str = "#{@str} || #{@or_condition}"  if @or_condition
    end
    @str
  end

  # factory methods

  def self.ge(attr, value)
    new(attr, value, true, false, true)
  end

  def self.gt(attr, value)
    new(attr, value, true, false, false)
  end

  def self.le(attr, value)
    new(attr, value, false, true, true)
  end

  def self.lt(attr, value)
    new(attr, value, false, true, false)
  end

  def self.eq(attr, value)
    new(attr, value, false, false, true)
  end
end

class Symbol
  def ge(value); Condition.ge(self, value) end
  def gt(value); Condition.gt(self, value) end
  def le(value); Condition.le(self, value) end
  def lt(value); Condition.lt(self, value) end
  def eq(value); Condition.eq(self, value) end
end

class String
  def ge(value); Condition.ge(self.to_sym, value) end
  def gt(value); Condition.gt(self.to_sym, value) end
  def le(value); Condition.le(self.to_sym, value) end
  def lt(value); Condition.lt(self.to_sym, value) end
  def eq(value); Condition.eq(self.to_sym, value) end
end

class OpenTable

  def initialize(attrs = nil)
    @attrs = []
    @columns = {}
    add_attrs(attrs) if attrs
  end

  def add_attr(attr)
    add_attrs([attr])
  end

  def add_attrs(attrs)
    attrs.each do |a|
      unless @attrs.include?(a)
        @attrs << a
        @columns[a] = []
      end
    end
  end

  def remove_attr(attr)
   remove_attrs([attr])
  end

  def remove_attrs(attrs)
    attrs.each do |a|
      @attrs.delete(a)
      @columns.delete(a)
    end
  end

  alias add_column add_attr
  alias add_columns add_attrs
  alias remove_column remove_attr
  alias remove_columns remove_attrs

  def [](index)
    if index.is_a?(Integer)
      row_array(index)
    elsif index.is_a?(Hash)
      # form a chain of and'd conditions
    end
  end

  def append(**args)
    @attrs.each do |a|
      @columns[a] << args[a]
    end
  end

  def <<(**args)
    append(**args)
  end

  def row_array(index)
    @columns.collect{|a,vals| vals[index]}
  end

  def row_csv(index)
    row_array.to_csv
  end
  def row_hash(index)
    h = {}
    @columns.each do |attr,vals|
      h[attr] = vals[index]
    end
    h
  end

  def row_json(index)
    row_hash(index).to_json
  end
end