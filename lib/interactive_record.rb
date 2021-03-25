require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  #to string, downcase, then add an s
  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.column_names
    column_names = []
    sql = "pragma table_info('#{table_name}')" # grabs column properties
    table_info = DB[:conn].execute(sql)
    table_info.each do |row|
      column_names << row["name"] #"name" is one of the column properties
    end
    column_names.compact
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |x|
      values << "'#{send(x)}'" unless send(x).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|x| x == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute_hash)
    value = attribute_hash.values.first
    format_value = "'#{value}'"
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{format_value}"
    DB[:conn].execute(sql)
  end
end
