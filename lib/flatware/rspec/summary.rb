Flatware::RSpec::Summary = Struct.new(:duration, :example_count, :failure_count, :pending_count) do
  def +(other)
    self.class.new duration + other.duration,
      example_count + other.example_count,
      failure_count + other.failure_count,
      pending_count + other.pending_count
  end

  def failed_examples

  end

  def fully_formatted
    "fully formatted!"
  end
end
