#!/usr/bin/env python

from __future__ import print_function
from subprocess import call
from threading import Thread
from Queue import Queue, Empty

import paramiko
import platform
import shlex
import sys
import time


def ssh_thread(**kwargs):
    queue = kwargs["queue"]
    host = kwargs["host"]
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    while True:
        client.connect(host)
        transport = client.get_transport()
        transport.set_keepalive(1)
        channel = transport.open_session()
        channel.get_pty()
        channel.set_combine_stderr(True)
        channel.exec_command("tail -f -n0 /var/log/rpcdaemon.log")
        stdout = channel.makefile("rb")

        try:
            for line in stdout:
                queue.put(line)
        except:
            client.close()
            time.sleep(1)
            continue


def local_thread(**kwargs):
    queue = kwargs["queue"]
    logfile = open("/var/log/rpcdaemon.log", "r")
    # Seek to end
    logfile.seek(0, 2)

    while True:
        where = logfile.tell()
        line = logfile.readline()
        if not line:
            time.sleep(1)
            logfile.seek(where)
        else:
            queue.put(line)

def restart_services():
    time.sleep(5)
    call(shlex.split("service neutron-plugin-openvswitch-agent restart"))
    call(shlex.split("service neutron-l3-agent restart"))


def main(argv):
    ourhost = platform.node()
    queue = Queue()
    threads = [
        Thread(target=ssh_thread, kwargs={"queue": queue, "host": argv[1]}),
        Thread(target=local_thread, kwargs={"queue": queue})
    ]
    for thread in threads:
        thread.daemon = True
        thread.start()

    while True:
        try:
            while all(map(lambda t: t.is_alive(), threads)):
                try:
                    line = queue.get(timeout=0.1).strip("\n")
                    if ourhost+"/L3" in line and "Scheduling" in line:
                        print("Restarting our services")
                        Thread(target=restart_services).start()
                    queue.task_done()
                except KeyboardInterrupt:
                    raise
                except Empty:
                    continue
                except:
                    raise
        except KeyboardInterrupt:
            break
        except Exception as e:
            print("Exception caught: {}, reticulating splines...".format(e.msg))
        finally:
            return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {} remotehost".format(sys.argv[0]))
        sys.exit(-1)

    sys.exit(main(sys.argv))
