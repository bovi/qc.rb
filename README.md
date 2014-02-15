qc.rb
=====

QingCloud API Library to handle instances, networks, etc. on QingCloud.com

### Installation

You can install *qc.rb* via RubyGems:

```
gem install qc.rb
```

### Important Notice

I'm not a native chinese speaker! Yet the complete documentation of QingCloud.com is in chinese! Due to that it is reasonable to expect that my understanding of the API might not be 100% correct! You are very welcome to improve the code!

### Usage

You can use *qc.rb* via *qc* as a CLI or direct as a Ruby library.

#### SSH

Get all public keys:

CLI Version:

```
qc ssh list
```

.rb Version:

```
# Each Public Key is available in *s*
QC::SSH.each {|s| puts s}
```

#### Instances

Get all instances:

CLI Version:

```
qc ins list
```

.rb Version:

```
# Each instance is available in *i*
QC::Instance.each {|i| puts i}
```
