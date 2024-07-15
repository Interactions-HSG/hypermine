import os
from subprocess import Popen, run
from time import sleep

import test_hym_player_control
import test_player_move_to

p_minetest_server = Popen(["docker", "compose", "up"])
p_minetest_client = Popen(["minetest", "--go", "--address", "172.18.0.2", "--name", "agent0"])
# allow client to connect
sleep(5)

tests = {
    "hym_player_control": test_hym_player_control.run_tests,
    "player_move_to": test_player_move_to.run_tests,
}

try:
    for name, test in tests.items():
        test()
    print("=== SUCCESS ===")
except AssertionError as err:
    print(f"=== FAILED {name}")
    raise
finally:
    p_minetest_client.terminate()
    p_minetest_server.terminate()
    run(["docker", "stop", "minetest"])
    run(["docker", "rm", "minetest"])