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
