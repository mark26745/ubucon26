set dotenv-load := true

clean:
    @echo "Cleaning PX4 build, logs, and temporary files..."
    rm -rf firmware/px4/build
    rm -rf tlogs
    rm -rf .venv_container
    @echo "Clean complete!"

build-sitl:
  uv run --directory firmware/px4 make px4_sitl_default

sitl: build-sitl
  uv run --directory firmware/px4 ./build/px4_sitl_default/bin/px4

sim: build-sitl
  hivemind

docker-sim:
  podman compose -f docker/docker-compose.yml up

proxy:
  uv run mavproxy.py --state-basedir=./tlogs --aircraft=demo --master=udp:127.0.0.1:14550 --out=udp:127.0.0.1:14551 --out=udp:127.0.0.1:14552

sitl-dds-agent:
  MicroXRCEAgent udp4 -p 8888

ros2-subscribe-sensors:
    @echo "Waiting for PX4 SITL to start publishing..."
    bash -c 'until ros2 topic list | grep -q "/fmu/out/sensor_combined"; do sleep 1; done'
    @echo "Topic found! Starting subscriber..."
    ros2 topic echo /fmu/out/sensor_combined

