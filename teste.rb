require "csv"
require 'benchmark'

# require "sequel"

# DB = Sequel.connect("postgres://fabio:@127.0.0.1:5432/cnpj")
# n = 5000000


src_dir = "./files/Estabelecimentos1.csv"
dst_dir = "./files/Estabelecimentos1_fixed.csv"

# puts " Reading data from  : #{src_dir}"
# puts " Writing data to    : #{dst_dir}"

# create a new file
csv_out = File.open(dst_dir, "wb")

# read from existing file
idx = 0
# "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
#

result = Benchmark.realtime do
  CSV.foreach(src_dir, headers: false, encoding: "CP1252:UTF-8", col_sep: ";", quote_char: '"', skip_blanks: true) do |row|
    # break if idx == 54_000 # 7 segundos

    cnpj = row[0] + row[1] + row [2]

    newrow = [cnpj, *row]

    newrow = newrow.map do |col|
      fixed_col = col
        .gsub('"', '""') # corrige o caracter " dentro das colunas
        .gsub("\\", "\\\\\\") # corrige o caracter / dentro das colunas, ruby usa 6 slashes pra dizer que é literal

      "\"#{fixed_col}\""
    end

    # newrow = newrow.map do |col|
      # if col.empty?
        # puts "achei uma empty"
        # col
      # else
        # puts "essa nao ta empty"
        # puts col

        # "\"#{col.gsub('"', "\\\"").gsub(/\s+/, "")}\""
        #
      # end
      # return col if col.empty?
      # "\"#{col.gsub('"', "\"").gsub(/\s+/, "")}\""
    # end

    csv_out << newrow.join(";").encode('utf-8') + "\n"
    # idx += 1
  end
end

puts result
# close the file
csv_out.close
