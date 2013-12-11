RSpec::Matchers.define :perform_in do |goal|
  match do |actual|
    @time = Benchmark.realtime do
      actual.call
    end

    @time < goal
  end

  failure_message_for_should do |actual|
    "It took too long. Goal: #{goal}, Benchmark: #{@time}"
  end

  failure_message_for_should_not do |actual|
    "It did not take long enough. Goal: #{goal}, Benchmark: #{@time}"
  end
end