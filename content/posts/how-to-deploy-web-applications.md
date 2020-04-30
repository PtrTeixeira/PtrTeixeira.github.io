+++
draft = true
date = 2020-04-15T23:36:22-04:00
title = "How I Deploy Web Applications"
slug = "how-i-deploy"
tags = ["software"]
+++

# How I Deploy

Someone once asked me how I deploy web applications. So I'm
writing this as something between a step-by-step guide to deploying
applications and a story about how I learned to deploy web apps.
As a result, no part of this should be taken as a definitive guide
to how to how applications *should* be deployed. It's limited both
because I'm still working through better ways to deploy applications
and because I only manage limited amounts of software and hardware
at once.

This series expects a reasonable familiarity with the command-line;
in particular, you should be familiar with SSH. Otherwise (and including SSH, actually) I'll try to link to or provide resources
for other skills that I bring up.

## Getting a VPS

First: Why use a virtual private server? Aren't there better, more
modern, more managed ways to deploy applications? Both serverless
models (like Google Cloud Run or AWS Lambda) and managed applications
(like AWS ElasticBeanstalk or Google AppEngine) will handle
provisioning and scaling hardware for you. Even a managed Kubernetes
service (like GKE or AKS) will free you from looking after the
fundamentals of your server.

Which, of course, is why I wanted to use a VPS. Part of what I wanted
to learn was how to run a server. Cloud-managed services will get
you pretty far but there's definitely a point where you're limited
(either cost-wise or by hardware or OS issues or something else) where
you need to understand that you are running code on real hardware.

Plus, once you're comfortable working on the commandline you seem
wicked smaht.

### Choosing a Hosting Provider

For the purpose of following this guide, I'm going to be using
DigitalOcean. DigitalOcean doesn't have a free tier, but if you
haven't used it before you can get a pretty large ($100, or
20 months of a $5/mo server) credit to start with.

You can also use Linode or Vultr, which are very similar to
DigitalOcean, or a larger hosting provider, like Google Cloud
or AWS. I *currently* use Google Cloud Platform, which has
a very reasonable free tier for a VPS, which is great since I've
used my free credit with both AWS and DigitalOcean. The primary
disadvantage of a hosting provider like AWS or GCP (or Microsoft
Azure, or another large hosting provider) is that the web
console is both intimidating and very hard to use. Smaller
VPS providers have, in my experience, much better dev consoles.
You're also much more likely to have a better experience with
support at a smaller provider than at a big one.

### Picking Up Your Hardware

Go to [Digital Ocean](https://digitalocean.com) and create an
account. Once you're logged in, it will prompt you to create a
Droplet, which is what DigitalOcean calls its VPS instances, from a
screen that looks something like this:

![DigitalOcean home](/me/images/DigitalOcean_home.png)

Clicking "Create a Droplet" will bring you to the next page,
where you can select the OS, instance size, and instance location.
My recommendation is Ubuntu 18.04. Ubuntu is an extremely common
operating system, which means that almost any tutorial geared
toward Linux (including this one!) is actually designed for
Ubuntu. If you are want to experiment and are willing to
look up how to adapt instructions for your particular distribution,
you can choose any distribution that you like.

Your instance location also doesn't matter a huge amount. Nearer
to you will provide ever so slightly better connection speed,
but unless you are deploying something that relies on real-time
performance it's unlikely to make a huge difference. The most
important decision you can make on this page is instance size.
If you pick incautiously it can cost you a lot of money, so be
careful!

In my experience DigitalOcean will start the instance size selection
somewhere in the middle. You should scroll all the way over to the
left and select the $5/mo instance size, which will give you 1GB RAM
and 1 CPU. That should be more than enough space to get started
deploying your application.

Finally, DigitalOcean will prompt your for how you want to connect
to your instance, giving you the choice between using a password
(less secure!) and using an SSH key (more secure!). You should
probably use an SSH key. When you click "New SSH Key," DigitalOcean
will prompt you for your public key, and give you instructions on
how to generate a new SSH key. You can copy your public key into
the provided space, then scroll all the way to the bottom of page
and click "Create Droplet" to finish setting up your instance.

## Connecting to Your Instance

Now your VPS should be all set up. The UI will show you a
public IP address, which is how you can connect to your
droplet. It should look something like:

![DigitalOcean Droplet home](/me/images/DigitalOcean_droplet.png)

You can see the droplet that I've created (named `do-1`), with
the public IP address `64.225.11.136` and the tag `frontend`.

You can connect to your droplet with

```bash
ssh root@64.225.11.136
```

Where you've replaced my IP address with the IP address from
your droplet. If you have multiple SSH keys and the SSH key you
added to DigitalOcean wasn't saved as `id_rsa`, then you may need
to use `ssh -i <path-to-your-ssh-key> root@ip` instead.

Once you connect, you'll receive a prompt that begins "The
authenticity of host ... can't be established." You should check that
the IP address you entered on the command line is indeed the one
that you want to connect to, then type "yes" in order to proceed.
(This isn't the safest way to proceed; in an ideal world you'd check
the fingerprint against a known one, or generate and sign the host
key yourself in order to verify that you were connecting to the
computer you thought you were connecting to. But since we haven't
don't know the host's SSH key, we just need to assume we're doing
the right thing and move on.)

## Deploying Your Application

### Running a Server

Before we get to deploying *your* application, I'm going to
show you how to run *an* application. That seems a little bit
backwards, and it kind of is. But it's much easier to talk about
running an application if I know what it is, and I don't know
how to run your application. So I'm going to walk through how to
run an application, then jump backward to deploying your application
and connect the dots from there.

After you've SSH'ed into your droplet, you can run

```bash
python3 -m http.server
```

on command line in your droplet. That should bring up the message
"Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000)" in the
terminal.

You can open up `http://<your-droplet-ip>:8000` in your
web browser on your local computer to see a list of files
in your home directory on the droplet. In the droplet, you should
see a log of all the requests that were made to your local machine.

You can press <kbd>Ctrl-C</kbd> on your droplet to stop the Python
program (Don't keep it open for long! If you can view those files
in your web browser, so can anyone else).

The big problem with running an application in the foreground of your
SSH session is that now you can't quit your SSH session - you need
to kill the running program to get back to the terminal so you can
exit out of your SSH session.

If you're familiar with shell scripting, it might seem like the easy
solution to this is just to send your program to the background, by
running `python3 -m http.server &` (where the final `&` tells bash)
to run the python script in the background, leaving you in your
shell). This works fine so long as you stay connected to your
droplet, but if you quit out of your SSH session, your Python program
will also stop. If you ran your program in the foreground of your
droplet earlier and tried to quit the SSH session without killing
the program by closing your terminal, the same thing would happen -
as soon as the SSH connection dropped, Linux will kill all the
programs that you started.

### Staying Alive with Tmux

There are several ways that you can keep your program running after
you disconnect from your SSH session, but the easiest way is to use
`tmux` to hold onto the session even after you disconnect.

`tmux` should be installed by default on your droplet, so you can just
run `tmux` on the command line to get started. It should drop you
into a shell like the one you were just in, albeit with a green bar
at the bottom.

`tmux` allows you to do several different things, but the most
important for this is the ability to attach and detach from the
running session.

You can try running

```bash
$ echo "Hello!"
$ tmux detach
```

from inside your tmux session:

![DigitalOcean tmux](/me/images/DigitalOcean_tmux.png)

Doing so should drop you back into your original shell, with the shell history you had before. Now you can run

```bash
tmux attach
```

to get back inside the tmux session - you should see the
`echo 'Hello!'` that you ran before.

Alright, that's all the background you need. From inside a
tmux session, run `python3 -m http.server` and hit
<kbd>Ctrl-b d</kbd> (that is, ctrl and b together, then just d -
the shortcut for `tmux detach`). You can now `exit` from your SSH
session, and python will keep running while you're gone.

When you want to stop the Python server - which you should do
sharpish - you can SSH back into your server and run `tmux attach`
to bring Python back into the foreground. A simple `Ctrl-C` will
bring your server back down.

`tmux` isn't the most graceful way to run an application. It
certainly isn't the way you'll run a server in production at any
company you'd ever want to work at. It won't tell you when your
program crashes, or start it automatically on boot, or give you
a way to check the logs other than SSH'ing into the server and
re-attaching to the tmux session. But if all you're trying to do
is get a quick demo off the ground and share it with other people,
`tmux` is an excellent place to get started. (There are other,
even simpler ways - like using `nohup` or `disown` - but they
make it even harder to check back in on what your application is
doing).

### Alright, But What About My Application?

But now what about your application? Unfortunately, I don't know what
your application looks like, so it's hard for me to give you precise
guidelines on how to deploy it.

In the easiest case, the thing you want to deploy is just a single file or directory. In this case, you can just use `scp` to copy
your files over to your droplet, the same way you've been logging in.

For example, if you just have a `server.py` file, you can run

```bash
scp /path/to/server.py root@<your-droplet-ip>:~
```

("secure copy") on your local machine. It will copy your `server.py`
file into the `/root` directory on your local machine. From there,
you can start it in a tmux session, and it will behave just as if you
were running it locally - except, of course, that it's running on a different machine.

It works the same way if you have a collection of files rather than
a single file - you can `scp` a directory in the same was as using
`cp` locally, except it will copy it onto your droplet.

This does get a little more complicated if your application has other
dependencies, though. While you could simply copy your whole project
directory over, most of the time it's faster and easier to re-download
your dependencies on your droplet instead. There's also no guarantee
that the dependencies you have installed will work on your droplet.
This is often the case if you're developing on Mac or Windows and
your Python or Node project has dependencies that have dependencies
that depend on C or C++.

So suppose you have (for example) a Python project where you've been
installing dependencies with `pip` (and carefully maintaing a record
of what you've installed with `pip freeze`!). Then you can `scp` your
files, including the list of what you've installed, onto your droplet.
From there you can use `pip install` to install your dependencies on
the droplet[^1]. After that, your application should be a-okay.

Of course, there are many more things that you might depend on - if
your application is written in Java, you'll need to install Java
(with, for example, `apt-get install openjdk-11-jre`); if your
application is written in NodeJS, you'll need to install it
(following the instructions [here](https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions) for
the version of NodeJS that you need). But in general, the pattern
is the same - copy the files you need from your local machine onto
your remote machine, install its dependencies. From there you can
run your application.


## Getting a Domain Name

So now you've got your application running on your server, and you
can reach it in your web browser by typing in your server's IP
address. If you want to, there's one last step you need to do -
get a domain name for your application. This will cost more money,
though not that much - you can typically get a domain name for around
$10 / year.

There are many companies that will sell you domain names - if you
google "domain registrar" you will find many of them. [Namecheap](namecheap.com), [Domain.com](domain.com), and [GoDaddy](godaddy.com)
are some of the more famous ones.


[^1]: You may need to `apt-get install python-pip` (for Python 2) or `apt-get install python3-pip` (for Python 3) in order to install `pip`.