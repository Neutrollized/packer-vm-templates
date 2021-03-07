# README
Before you can begin to build with Packer on Azure, you will need to create a service principal with `client_id` and `client_secret`.  You can do that either from the Portal (except if you won't find "service principals", you create them under "App registrations"...) or you can create them from command-line:

`az ad sp create-for-rbac --name Packer --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"`

## Useful `az` commands
- [`az vm image list`](https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az_vm_image_list)
- [`az vm list-sizes`](https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az_vm_list_sizes)

## Sample usage
`packer build -var-file=variables.pkrvars.hcl ol7_base.pkr.hcl`

where my **variables.pkrvars.hcl** file would be something like:
```
client_id       = "abcdefgh-1234-5678-9012-abcdefghijkl"
client_secret   = "mySup3rS3cre7!"
subscription_id = "12345678-abcd-efgh-ijkl-1234567890ab"
tenant_id       = "zyxwvuts-9876-5432-1098-zyxwvutsrqpo"

managed_image_rg_name = "mystorageaccount-rg"
```


## Misc.
Below are some miscellaneous data of some tuning and IOPs testing I did.

[Disk cache settings](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-design#disk-cache-settings)

[Optimize performance on Linux VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/premium-storage-performance#optimize-performance-on-linux-vms)

### IOPs perf testing testing
While in /opt/oracle/oradata (where the 512GB Premium SSD is mounted -- Max IOPs 2300, Max throughput 150 MBps):

`fio --name=randrw --rw=randrw --direct=1 --ioengine=libaio --bs=4k --numjobs=1 --rwmixread=75 --size=1G --runtime=300 --group_reporting`
- 1 job
- 75/25 read/write split


#### OL7.9-LVM / Gen 1 / DS1_v2
Output:
```
randrw: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=1
fio-3.7
Starting 1 process
Jobs: 1 (f=1): [m(1)][100.0%][r=5312KiB/s,w=1736KiB/s][r=1328,w=434 IOPS][eta 00m:00s]
randrw: (groupid=0, jobs=1): err= 0: pid=16543: Fri Mar  5 21:06:32 2021
   read: IOPS=1202, BW=4809KiB/s (4924kB/s)(768MiB/163454msec)
    slat (usec): min=4, max=4455, avg=12.61, stdev=17.34
    clat (nsec): min=1900, max=17819k, avg=278055.30, stdev=187381.58
     lat (usec): min=33, max=17976, avg=290.89, stdev=189.71
    clat percentiles (usec):
     |  1.00th=[   52],  5.00th=[   80], 10.00th=[  114], 20.00th=[  163],
     | 30.00th=[  190], 40.00th=[  217], 50.00th=[  247], 60.00th=[  281],
     | 70.00th=[  326], 80.00th=[  383], 90.00th=[  465], 95.00th=[  537],
     | 99.00th=[  725], 99.50th=[  848], 99.90th=[ 1827], 99.95th=[ 2835],
     | 99.99th=[ 5276]
   bw (  KiB/s): min= 3536, max= 5976, per=99.96%, avg=4806.26, stdev=352.59, samples=326
   iops        : min=  884, max= 1494, avg=1201.54, stdev=88.16, samples=326
  write: IOPS=401, BW=1606KiB/s (1645kB/s)(256MiB/163454msec)
    slat (usec): min=6, max=1463, avg=16.16, stdev=19.15
    clat (usec): min=725, max=79971, avg=1593.39, stdev=632.26
     lat (usec): min=1128, max=79989, avg=1609.78, stdev=632.82
    clat percentiles (usec):
     |  1.00th=[ 1237],  5.00th=[ 1303], 10.00th=[ 1336], 20.00th=[ 1385],
     | 30.00th=[ 1418], 40.00th=[ 1450], 50.00th=[ 1483], 60.00th=[ 1516],
     | 70.00th=[ 1565], 80.00th=[ 1614], 90.00th=[ 1778], 95.00th=[ 2114],
     | 99.00th=[ 4293], 99.50th=[ 5145], 99.90th=[ 7898], 99.95th=[ 8848],
     | 99.99th=[10683]
   bw (  KiB/s): min= 1304, max= 1880, per=99.99%, avg=1605.78, stdev=98.61, samples=326
   iops        : min=  326, max=  470, avg=401.44, stdev=24.65, samples=326
  lat (usec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.62%
  lat (usec)   : 100=5.56%, 250=31.88%, 500=31.58%, 750=4.66%, 1000=0.47%
  lat (msec)   : 2=23.67%, 4=1.23%, 10=0.32%, 20=0.01%, 100=0.01%
  cpu          : usr=0.83%, sys=2.28%, ctx=263624, majf=0, minf=13
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=196498
```
Summary:
- read IOPS = 1202
- write IOPS = 401


#### OL7.9-LVM / Gen 2 / D2s_v3
Output:
```
randrw: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=1
fio-3.7
Starting 1 process
randrw: Laying out IO file (1 file / 1024MiB)
Jobs: 1 (f=1): [m(1)][100.0%][r=6158KiB/s,w=2090KiB/s][r=1539,w=522 IOPS][eta 00m:00s]
randrw: (groupid=0, jobs=1): err= 0: pid=10598: Sat Mar  6 00:30:16 2021
   read: IOPS=1340, BW=5362KiB/s (5490kB/s)(768MiB/146593msec)
    slat (usec): min=4, max=1099, avg=10.16, stdev= 7.68
    clat (usec): min=12, max=201794, avg=239.95, stdev=503.58
     lat (usec): min=35, max=201801, avg=250.27, stdev=503.90
    clat percentiles (usec):
     |  1.00th=[   48],  5.00th=[   64], 10.00th=[   85], 20.00th=[  153],
     | 30.00th=[  174], 40.00th=[  194], 50.00th=[  217], 60.00th=[  241],
     | 70.00th=[  273], 80.00th=[  306], 90.00th=[  363], 95.00th=[  412],
     | 99.00th=[  652], 99.50th=[ 1434], 99.90th=[ 2606], 99.95th=[ 3785],
     | 99.99th=[ 6718]
   bw (  KiB/s): min= 4040, max= 6736, per=100.00%, avg=5360.96, stdev=428.60, samples=293
   iops        : min= 1010, max= 1684, avg=1340.22, stdev=107.16, samples=293
  write: IOPS=447, BW=1791KiB/s (1834kB/s)(256MiB/146593msec)
    slat (usec): min=6, max=2301, avg=13.31, stdev=17.66
    clat (usec): min=981, max=23160, avg=1462.29, stdev=897.52
     lat (usec): min=990, max=23175, avg=1475.78, stdev=897.72
    clat percentiles (usec):
     |  1.00th=[ 1090],  5.00th=[ 1156], 10.00th=[ 1188], 20.00th=[ 1221],
     | 30.00th=[ 1254], 40.00th=[ 1270], 50.00th=[ 1303], 60.00th=[ 1336],
     | 70.00th=[ 1369], 80.00th=[ 1418], 90.00th=[ 1549], 95.00th=[ 2008],
     | 99.00th=[ 5997], 99.50th=[ 8356], 99.90th=[12256], 99.95th=[13435],
     | 99.99th=[16319]
   bw (  KiB/s): min= 1288, max= 2232, per=99.98%, avg=1790.72, stdev=117.16, samples=293
   iops        : min=  322, max=  558, avg=447.68, stdev=29.29, samples=293
  lat (usec)   : 20=0.01%, 50=1.11%, 100=8.22%, 250=38.08%, 500=26.19%
  lat (usec)   : 750=0.70%, 1000=0.15%
  lat (msec)   : 2=24.08%, 4=1.02%, 10=0.39%, 20=0.07%, 50=0.01%
  lat (msec)   : 250=0.01%
  cpu          : usr=1.41%, sys=3.49%, ctx=262689, majf=0, minf=14
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=196498,65646,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=5362KiB/s (5490kB/s), 5362KiB/s-5362KiB/s (5490kB/s-5490kB/s), io=768MiB (805MB), run=146593-146593msec
  WRITE: bw=1791KiB/s (1834kB/s), 1791KiB/s-1791KiB/s (1834kB/s-1834kB/s), io=256MiB (269MB), run=146593-146593msec

Disk stats (read/write):
    dm-2: ios=196245/68301, merge=0/0, ticks=45309/107945, in_queue=153254, util=80.00%, aggrios=196498/70935, aggrmerge=0/72, aggrticks=45950/124050, aggrin_queue=104143, aggrutil=80.06%
  sdd: ios=196498/70935, merge=0/72, ticks=45950/124050, in_queue=104143, util=80.06%
```
Summary:
- read IOPS = 1340
- write IOPS = 447
