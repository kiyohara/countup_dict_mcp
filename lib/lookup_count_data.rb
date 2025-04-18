require 'csv'
require 'time'

class LookupCountData
  def initialize
    @data = {}
    load_data
  end

  def countup(word)
    word = word.downcase
    if @data[word]
      @data[word][:lookup_count] += 1
      @data[word][:updated_at] = Time.now
    else
      @data[word] = {
        word: word,
        lookup_count: 1,
        created_at: Time.now,
        updated_at: Time.now
      }
    end
    save_data
    @data[word][:lookup_count]
  end

  def get_count(word)
    word = word.downcase
    return 0 if @data[word].nil?
    @data[word][:lookup_count]
  end

  def get_updated_at(word)
    word = word.downcase
    return '' if @data[word].nil?
    @data[word][:updated_at].strftime('%Y-%m-%d %H:%M:%S')
  end

  def to_hash
    @data.values
  end

  private

  def load_data
    return unless File.exist?('lookup_count_data.csv')

    CSV.foreach('lookup_count_data.csv', headers: true) do |row|
      word = row['word']
      @data[word] = {
        word: word,
        lookup_count: row['lookup_count'].to_i,
        created_at: Time.parse(row['created_at']),
        updated_at: Time.parse(row['updated_at'])
      }
    end
  end

  def save_data
    CSV.open('lookup_count_data.csv', 'w') do |csv|
      csv << ['word', 'lookup_count', 'created_at', 'updated_at']
      @data.each_value do |record|
        csv << [
          record[:word],
          record[:lookup_count],
          record[:created_at].iso8601,
          record[:updated_at].iso8601
        ]
      end
    end
  end
end 