require './lib/flatware/pids'
require './lib/flatware/processor_info'

describe 'pids' do
  context 'group pids' do
    it 'should get all the pids of a group' do
      @group_leader_pid = Process.pid
      $0 = "flatware group leader"
      @child_pid = fork {
        $0 = "flatware child"
        sleep 1
      }
      Flatware.pids_of_group(@group_leader_pid).should include @group_leader_pid, @child_pid
    end
  end
end
