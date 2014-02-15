qc.rb
=====

QingCloud API Library to handle instances, networks, etc. on QingCloud.com

### Installation

You can install *qc.rb* via RubyGems:

```bash
gem install qc.rb
```

### Important Notice

I'm not a native chinese speaker! Yet the complete documentation of QingCloud.com is in chinese! Due to that it is reasonable to expect that my understanding of the API might not be 100% correct! You are very welcome to improve the code!

### Usage

You can use *qc.rb* via *qc* as a CLI or direct as a Ruby library.

#### SSH

Get all public keys:

CLI Version:

```bash
qc ssh describe
```

.rb Version:

```ruby
# Each Public Key is available in *s*
QC::KeyPair.describe {|s| puts s}
```

#### Instances

Get all instances:

CLI Version:

```bash
qc ins describe
```

.rb Version:

```ruby
# Each instance is available in *i*
QC::Instance.describe {|i| puts i}
```

Create new Instance:

```ruby
QC::Instance.run instance_name: 'NameOfInstance', login_keypair: 'kp-sadasd67' # => instance_id
```

Delete Instance:

```ruby
i = QC::Instance.load 'i-adssad7'
i.terminate! # => {"action"=>"TerminateInstancesResponse", "job_id"=>"j-asd7djk", "ret_code"=>0}
```

#### IPs

Get all IPs:

CLI Version:

```bash
qc ip describe
```

.rb Version:

```ruby
# Each IP is available in *i*
QC::Eip.describe {|i| puts i}
```

Allocate new IP:

```ruby
# Create IP width bandwidth 3MB
Eip.allocate bandwidth: 3   # => eip_id
```

Release IP:

```ruby
# Release IP with ID 'eip-12djpg8q'
Eip.load('eip-12djpg8q').release!   # => true | false
```

Change Bandwidth:

```ruby
# Change bandwidth of IP with ID 'eip-12djpg8q' to 2MB
ip = Eip.load('eip-12djpg8q')
ip.bandwidth = 2     # => 2
```

#### Volumes

Get all Volumes:

CLI Version:

```bash
qc vol describe
```

.rb Version:

```ruby
# Each Volume is available in *v*
QC::Volume.describe {|v| puts v}
```
