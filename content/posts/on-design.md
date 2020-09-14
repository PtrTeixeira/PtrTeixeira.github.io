+++
draft = false
date = 2020-09-10T20:12:42-04:00
title = "On Design"
slug = "on-design"
tags = ["technology"]
+++

I’ve been thinking about this for a while, and figured I’d put it down someplace. It starts out kinda technical, but I promise it’s actually a metaphor for something [^1].

In Linux there’s a particular syscall (`fork`) that lets you start a new process from a running process. It’s something that gets used all the time, and there’s nothing inherently weird about it. You call it, it starts a new process, and gives you back the ID of the new process. Unless it fails, in which case it returns -1 instead. Keep that in mind for a second.

There’s a second syscall (`kill`), that lets you shut down running processes. Again, it’s something that gets used all the time and there’s nothing particularly weird about it. You give it a process ID, and it tries to shut it down.

Well, that’s not quite true, there’s one particular weird thing about it. If you give it -1, instead of a real process ID, it will instead try to shut down every process running on your computer. Which, if you happen to be a privileged user, means you will shut down basically everything north of the  operating system. Which is bad.

So suppose you start a child process with `fork` and you save the process ID that it gives you. You do some more work, then decide to shut down the child process. But oop! `fork` failed, you ran `kill(-1)`, and everything on your computer has crashed.

Now, the obvious first thought here is “Don’t do that,” and you’re right. You shouldn’t do that. But maybe you didn’t know about this particular failure mode - it’s very uncommon! Maybe you did know, and you forgot. Maybe you didn’t forget, but you were in a hurry and you were very sure that just this time it’d be fine to skip some checks for now. The fact of the matter here is that this particular set of commands is a gun pointing at your foot. It’s all too easy to slip up and screw yourself over.

Talking about *how* to fix this is a little out-of-scope, but suffice to say that it doesn’t need to be this way. There are alternative ways to design this system such that you can’t do this. One of the major goals of programming language theory is to explore how to develop systems where mistakes like this are
impossible.

This example is specifically in computer science, because it’s what I do for work and what I spend a lot of time thinking about. But it’s not a problem that’s unique to computer science. If you’ve ever used a keyboard where the power button was way too close to the “delete” or “backspace” keys you’ve seen something similar. Ford needed to recall 10,000 SUVs because it put the  “sport mode” button right next to the “engine start/stop” button on the car dashboard, and drivers kept turning off the engine [^2]. 400 pilots in WWII crashed B-17s on landing because the flap controls and landing gear couldn’t be distinguished by touch, so pilots would come into land, accidentally adjust the flap controls, and try to land with the  landing gear still raised.

And just as with the `fork`/`kill` example, it’s very easy to write these off individually. What kind of idiot turns off the car
while driving down the highway? How dumb do you have to be to
accidentally not lower the landing gear on a huge plane?

But that line of thought misses a very fundamental point, which is that it’s possible to design a system such that it’s very
hard to make catastrophic mistakes, instead of very easy. It’s not easy to make systems work like that - as I said, even in the very narrow field of programming language theory doing so is many, many
open research questions. But conscientiously designed, incrementally improved systems are leagues better than ones that are haphazardly thrown together.

But the important part is that this isn’t about user-interface design or anything like that. *Everything* works like this. Every time you say, “Why don’t those chuckleheads just not do that? That’s obviously bad,” you instead get the opportunity to say, “How do we make it really easy to do the right thing and really hard to do the wrong thing?” How do we make it easier to invest than to gamble? How do we make it easier to not get addicted to pain medication than to become addicted? How do we make it as or more convenient to hang out digitally, rather than to hang out in person during a pandemic?

I have no idea what the answers to those questions are. It’d be really, really helpful if I did, but I don’t. I don’t even have a toolset for how to find answers to those questions. This is just something that I need to remind myself of sometimes - a lot of things that look like personal problems are systemic problems, and that there’s (hopefully) a systemic solution.

[^1]: This is based on [fork can fail](https://rachelbythebay.com/w/2014/08/19/fork/) by Rachel Kroll.
[^2]: This example, and the next one, are based on [The UX of LEGO Interface Panels](https://www.designedbycave.co.uk/2020/LEGO-Interface-UX/) by George Cave.
