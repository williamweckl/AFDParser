# -*- coding: utf-8 -*-
# Controle de Horas - Sistema para gestão de horas trabalhadas
# Copyright (C) 2009  O.S. Systems Softwares Ltda.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Rua Clóvis Gularte Candiota 132, Pelotas-RS, Brasil.
# e-mail: contato@ossystems.com.br

require 'afd_parser/record_parser'

class AfdParser::SetEmployee < AfdParser::RecordParser
  attr_reader :line_id, :record_type_id, :creation_time, :operation_type,
  :pis, :name

  OPERATION_TYPE = {"I" => :add, "A" => :edit, "E" => :remove}

  def initialize(line)
    self.line_id, self.record_type_id, self.creation_time,
    self.operation_type =
      line.unpack("A9AA12A").collect{|str| _clean!(str)}
    self.pis, self.name = line[23..-1].match(/\A(\d{1,12})(.{1,52})/)[1..2].collect{|str| _clean!(str)}
  end

  def export
    line_export = ""
    line_export += @line_id.to_s.rjust(9,"0")
    line_export += @record_type_id.to_s
    line_export += format_time(@creation_time)
    line_export += get_operation_letter(@operation_type).to_s
    line_export += @pis.to_s.rjust(12,"0")
    line_export += @name.ljust(52, " ")
    line_export
  end

  def self.size
    87
  end

  def ==(other)
    return self.class == other.class && [:line_id, :record_type_id, :creation_time, :operation_type, :pis, :name].all? do |reader|
      self.send(reader) == other.send(reader)
    end
  end

  private
  def line_id=(data)
    @line_id = well_formed_number_string?(data) ? data.to_i : data
  end

  def record_type_id=(data)
    @record_type_id = well_formed_number_string?(data) ? data.to_i : data
  end

  def pis=(data)
    @pis = well_formed_number_string?(data) ? data.to_i : data
  end

  def operation_type=(data)
    @operation_type = get_operation_type(data)
  end

  def name=(data)
    @name = data.rstrip
  end

  def creation_time=(raw_time)
    begin
      parsed_time = parse_time(raw_time)
      @creation_time = parsed_time
    rescue
      @creation_time = ""
    end
  end

  def get_operation_type(operation_type_letter)
    type = OPERATION_TYPE[operation_type_letter]
    if type.nil?
      raise AfdParser::AfdParserException.new("Unknown employee operation type letter '#{operation_type_letter}' found in line #{@line_id.to_s}")
    end
    type
  end

  def get_operation_letter(operation_type)
    OPERATION_TYPE.invert[operation_type]
  end
end
