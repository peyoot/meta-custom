本镜像使用的meta-custom分支：scarthgap-ros-igh-multidemo-ccmp25dvk

用于Digi开发板测试，包括实时Linux，ROS2+IgH EtherCAT Master+MoviIt ，基于webkit的ConnectCore-demo-example，QT例程等。

其中上电默认跑ConnectCore例程，按三下userbutton2会切换为QT例程，QT例程有两个，所有一共三个例程循环。

测试方法：
1、实时性能
后台默认跑例程，仍可以加压测试实时性能
#后台CPU0 满载（死循环）
taskset -c 0 sh -c 'while true; do :; done' &
#后台加IO压力
dd if=/dev/zero of=/dev/null bs=1M &
#确认后台任务已启动
jobs
#在前台运行 cyclictest
taskset -c 0 cyclictest -p 98 -t 3 -a 1 -m -l 50000
#测试结束杀后台任务
kill %1 %2 或 kill $(jobs -p)

2、ROS2 测试
注意如果后台在跑压力测实时，测试结束后应停止，再开始测试ROS
先 source /opt/ros/humble/setup.bash  ，这样ros2的环境就好了

source /opt/ros/humble/setup.bash
# 1. 检查 ROS 环境变量
echo $ROS_DISTRO
echo $ROS_VERSION

#2 检查 ROS 核心包是否安装
ros2 pkg list | grep -E "rclcpp|std_msgs|demo|ros_core"

#3 运行基础测试（ROS 2 推荐）
#3.1 启动 ROS 2 daemon（后台）
ros2 daemon start

#3.2 检查是否正常
ros2 daemon status

#3.3 测试 talker + listener（最经典的测试）
用screen或tmux新建Session, 以screen为例
screen -S ros_test
# screen终端 ros_test：
ros2 run demo_nodes_cpp talker

#3.4 按ctrl+a d 回原终端 ：
ros2 run demo_nodes_cpp listener

你应该能看到 talker 持续发布消息，listener 接收到消息。

#3.5 其它快速测试
ros2 node list
ros2 topic list
ros2 topic echo /chatter     # 如果有 talker 在跑

3. 配ethercat网口，并启用IgH EtherCAT

ip link                                          # 找到网口和它的 MAC
vi /etc/ethercat.conf
#   MASTER0_DEVICE="xx:xx:xx:xx:xx:xx"           # 填该网口 MAC
#   DEVICE_MODULES="generic"                     # 用通用驱动
systemctl start ethercat
systemctl status ethercat                        # active (exited) 为正常

接上真实从站测试



