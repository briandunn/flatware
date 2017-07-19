describe Flatware::Job do
  def job(id, duration)
    Flatware::Job.new(id, duration: duration)
  end

  describe '.pack' do
    it 'balences by duration' do
      long = job(1, 1)
      short_1 = job(2, 0.5)
      short_2 = job(3, 0.5)
      jobs = [ long,short_1,short_2 ]
      expect(Flatware::Job.pack(jobs,2)).to match_array [
        job([1], 1), job([3,2],1)
      ]
    end

    it "doesn't return empty groups" do
      long = job(1, 1)
      expect(Flatware::Job.pack([long],2)).to eq [
        job([1], 1)
      ]
    end
  end
end
