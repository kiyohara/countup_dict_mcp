require 'json'
require 'model_context_protocol'
require_relative 'lib/lookup_count_data'

def log(message)
  File.open("log.txt", "a") do |log_file|
    log_file.puts("[#{Time.now}] #{message}")
  end
end

class CheckWordPrompt < ModelContextProtocol::Server::Prompt
  with_metadata do
    {
      name: "Check Word Prompt",
      description: "Check the word",
      arguments: [
        {
          name: "word",
          description: "The word you want to check",
          required: true
        }
      ]
    }
  end

  def call
    base_prompt = File.read("prompt.txt", encoding: 'UTF-8')
    word = params["word"].downcase
    lookup_count_data = LookupCountData.new
    count = lookup_count_data.get_count(word)
    updated_at = lookup_count_data.get_updated_at(word)
    prompt = base_prompt.gsub("{{word}}", params["word"]).gsub("{{count}}", count.to_s).gsub("{{updated_at}}", updated_at.to_s)

    messages = [
      {
        role: "user",
        content: {
          type: "text",
          text: prompt
        }
      }
    ]

    respond_with messages: messages
  end
end

class ToolIncrementLookupCount < ModelContextProtocol::Server::Tool
  with_metadata do
    {
      name: "increment-lookup-count", # tool name must be kebab-case
      description: "Increment the lookup count of the word",
      inputSchema: {
        type: "object",
        properties: {
          word: { type: "string", description: "The word you want to increment the lookup count of" }
        },
        required: ["word"]
      }
    }
  end

  def call
    word = params["word"].downcase
    log("Increment Lookup Count tool called w/ word #{word}")

    lookup_count_data = LookupCountData.new
    new_count = lookup_count_data.countup(word)
    lookup_count_data.save_data

    respond_with(
      :text,
      text: { 'word': word, 'new_count': new_count }.to_json
    )
  end
end

class LookupCountResource < ModelContextProtocol::Server::Resource
  with_metadata do
    {
      name: "Lookup Count Resource",
      description: "The count of the word you looked up",
      mime_type: "text/plain",
      uri: "resource://lookup-count-data"
    }
  end

  def call
    lookup_count_data = LookupCountData.new
    
    respond_with(
      :text,
      text: JSON.pretty_generate(lookup_count_data.to_hash)
    )
  end
end

server = ModelContextProtocol::Server.new do |config|
  config.name = "countup-dictionary"
  config.version = "1.0.0"
  config.enable_log = true

  config.registry = ModelContextProtocol::Server::Registry.new do
    prompts list_changed: true do
      register CheckWordPrompt
    end

    resources list_changed: true do
      register LookupCountResource
    end

    tools list_changed: true do
      register ToolIncrementLookupCount
    end
  end
end

server.start