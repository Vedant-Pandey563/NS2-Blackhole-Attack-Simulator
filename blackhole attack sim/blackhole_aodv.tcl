# Create a simulator instance
set ns [new Simulator]

# Trace and NAM files
set tracefile [open blackhole_trace.tr w]
$ns trace-all $tracefile

set namfile [open blackhole.nam w]
$ns namtrace-all-wireless $namfile 800 600

# Parameters
set val(nn) 6
set val(x) 800
set val(y) 600
set val(rp) AODV
set val(chan) Channel/WirelessChannel
set val(prop) Propagation/TwoRayGround
set val(netif) Phy/WirelessPhy
set val(mac) Mac/802_11
set val(ifq) Queue/DropTail/PriQueue
set val(ll) LL
set val(ant) Antenna/OmniAntenna
set val(ifqlen) 50

# Topography and GOD
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

# Node Configuration
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channelType $val(chan) \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace ON

# Create nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    set node_($i) [$ns node]
    $node_($i) set X_ [expr rand()*$val(x)]
    $node_($i) set Y_ [expr rand()*$val(y)]
    $node_($i) set Z_ 0.0
}

# Simple mobility
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 1.0 "$node_($i) setdest [expr rand()*$val(x)] [expr rand()*$val(y)] 10.0"
}

# Setup TCP connection: Node 0 -> Node 4
set tcp [new Agent/TCP]
$ns attach-agent $node_(0) $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $node_(4) $sink

$ns connect $tcp $sink

set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 2.0 "$ftp start"

# Simulate Black Hole at node 5
# This node advertises itself but drops packets by using a Null agent
set null [new Agent/Null]
$ns attach-agent $node_(5) $null

# End the simulation
$ns at 20.0 "finish"

proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam blackhole.nam &
    exit 0
}

# Run it
$ns run
