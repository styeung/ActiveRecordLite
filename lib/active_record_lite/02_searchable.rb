require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    values = params.values

    where_line = params.keys.map do |x|
      "#{x} = ?"
    end.join(" AND ")

    result = DBConnection.execute(<<-SQL, *values)
    SELECT
    *
    FROM
    #{self.table_name}
    WHERE
    #{where_line}

    SQL

  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
