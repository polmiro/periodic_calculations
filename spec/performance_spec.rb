describe "Performance tests", :performance => true do
  PERIODS = 300
  DATA_POINTS_PER_INTERVAL = 3000

  before :all do
    ActiveRecord::Base.connection.execute("DELETE   FROM activities;")

    @time = Time.now
    PERIODS.times do |days|
      inserts = []

      DATA_POINTS_PER_INTERVAL.times do |quantity|
        quantity = 4000 + (quantity * 100)
        created_at = @time - days.days
        inserts << "(#{quantity}, '#{created_at.utc}')"
      end

      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO activities(quantity, created_at) VALUES #{inserts.join(", ")}
      SQL
    end
  end

  after :all do
    ActiveRecord::Base.connection.execute("DELETE   FROM activities;")
  end

  it "should be performant with non cumulative queries" do
    expect do
      Activity.periodic_sum(:quantity, @time - PERIODS.days, @time).result
    end.to perform_in(1)
  end

  it "should be performant cumulative queries" do
    expect do
      Activity.periodic_sum(:quantity, @time - PERIODS.days, @time, :cumulative => true).result
    end.to perform_in(1)
  end

end