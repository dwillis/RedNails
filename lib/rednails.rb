#
# Copyright (c) 2006, Ubiquitous Business Technology (http://ubit.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#    * Neither the name of Ubit nor the names of its
#      contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# == Author
# Zev Blut (zb@ubit.com)

require 'net/http'

class RedNails
  attr_reader :variables

  # Takes a marked template file and an optional boolean that determines if an
  # exception should be raised on errors.
  def initialize(templatefile, raises_exception = false)
    @templatefile = templatefile
    @variables = nil
    @repetitions = Hash.new
    @regexp = parse_template(templatefile)
    @excepts = raises_exception
  end

  # Takes a string of data to scrape.
  # returns an array of variables defined in the templatefile
  def parse(text)
    #10 seconds timeout
    #because those huge regular expressions can take a LONG time if there is no match
    m = nil
    begin
      timeout(10) do
        m = @regexp.match(text)
      end
    rescue => err
      raise "REGEXP TIMEOUT!"
    end

    if m.nil?
      if @excepts
        raise "REGEXP from #{@templatefile} IS::::::::::::::::::::::::\n#{@regexp.source}" +
          "COULD NOT MATCH PAGE TEXT:::::::::::::::::::::::::::::\n#{text}"
      end
      return nil
    end

    vals = []
    # the ... means 1 to val -1 so all of the matches
    (1...m.size).each do |i|
      if @repetitions.key?(i)
        reg = @repetitions[i][0]
        vals<< m[i].scan(reg)
      else
        vals<< m[i]
      end
    end
    return vals
  end

  # Takes a string of data to scrape.
  # Returns a Hash with the template variable names as keys and matching
  # scraped data as values.
  def parse_hash(text)
    vals = parse(text)
    return nil if vals.nil?
    hvals = {}
    # Can probably do a block pass an yield instead of this.
    vals.each_index do |i|
      if @repetitions.key?(i+1)
        varnames = @repetitions[i+1][1]
        k=1
        vals[i].each do |valcombo|
          valcombo.each_index do |j|
            hvals["#{varnames[j]}_#{k}"] = valcombo[j]
          end
          k+=1
        end
      else
        hvals[@variables[i]] = vals[i]
      end
    end
    return hvals
  end

  def print_detailed
    puts "RedNails Detailed Info"
    puts "-----------Regular Expression Source--------------"
    puts @regexp.source
    puts "--------------------------------------------------"
    puts "-----------Variables------------------------------"
    puts @variables.inspect
    puts "--------------------------------------------------"
    puts "-----------Repetitions------------------------------"
    puts @repetitions.inspect
    puts "--------------------------------------------------"
  end

  ###########################################################################
  private

  def parse_template(template)
    templatetext = File.open(template,"r") { |f| f.read }
    literals = Array.new
    tail = ""
    @variables = Array.new

    tmptext = templatetext
    while m = /(.*?)\#\{(.*?)\}(.*)/mi.match(tmptext)
      literals << m[1]
      @variables<< m[2]
      tail = m[3]
      tmptext = m[3]
      reps,repnames = check_for_repetition(m[2])
      if reps.class() == Regexp
        @repetitions[@variables.size] = [reps,repnames]
      end
    end
    # push the last matched tail onto the list
    literals<< tail

    literals = literals.map do |lit|
      litexp = ""
      # find all the whitespace items and condense to \s
      split = lit.squeeze("\s\t\n\r\f").split(/\s/)
      split.each_index do |i|
        if split[i] != ""
          litexp<< Regexp.escape(split[i])
          # put a regexp for \s if it is not the last lit
          # because we do not want to eat the spaces in a variable
          if  i != (split.size - 1)
            litexp<< "\\s*"
          end
        else
          litexp<< "\\s*"
        end
      end
      litexp
    end

    # generate the regular expression
    regexp = "\\s*"
    literals.each_with_index do |val,i|
      regexp<< literals[i]
      regexp<< "(.*)" if @variables.size > i
    end
    regexp<< "\\s*"

    return Regexp.new(regexp, Regexp::MULTILINE | Regexp::IGNORECASE)
  end

  def check_for_repetition(var)
    if m = /Rep:(.*)/mi.match(var)
      varnames = Array.new
      vals = m[1].scan(/(.*?)@(.*?)@(\S?)/mi)
      reg = ""
      vals.each do |lit,svar,taillit|
        varnames<< svar
        litexp = ""
        # find all the whitespace items and condense to \s
        split = lit.squeeze("\s\t\n\r\f").split(/\s/)
        split.each_index do |i|
          if split[i] != ""
            litexp<< Regexp.escape(split[i])
            # put a regexp for \s if it is not the last lit
            # because we do not want to eat the spaces in a variable
            if  i != (split.size - 1)
              litexp<< "\\s*"
            end
          else
            litexp<< "\\s*"
          end
        end
        reg<< "#{litexp}(.*?)#{Regexp.escape(taillit)}"
      end
      reg<< "\\s*"
      return Regexp.new(reg, Regexp::MULTILINE | Regexp::IGNORECASE),varnames
    else
      return var,nil
    end
  end

end
