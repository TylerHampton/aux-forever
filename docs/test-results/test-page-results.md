# Test page results (Claude's test page, exported 2026-11-19)

Tyler marked each in-game step on a claude.ai test page (`https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ`, private to
Tyler; Claude-only tooling). This file is a full export of what the page stored, so the record does not depend on it:
every build that has saved answers, each step's id, Pass/Fail/Skip (blank: Tyler sent only a note or screenshots), the
number of screenshots, and Tyler's note word for word. The steps themselves are in `TESTING.md` (current build) and
`docs/testing-history.md` (older ones), under the same build names; most results were also written there at the time.

Not exported: the screenshots. They show the game's chat (guild and other players' names) and Tyler's characters, and
this repository is public. Two notes had personal details; those words are marked as removed. Builds with no saved
answers (Tyler reported in the chat instead) are not listed: 0.6 build 6, 0.7 builds 1 to 3, 0.8 builds 6 and 11,
0.8.0.1, 0.8.2 builds 1 to 4 and 6, 0.8.2.1 build 5, and the `ah-facts-1` page.

## 0-6-release

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| auctions |  | 1 |  |
| buy | pass |  |  |
| open | pass |  |  |
| post | pass | 1 |  |
| recipe |  | 1 |  |
| sniper |  | 1 |  |

## 0-6-0-2-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| afterpost |  | 1 |  |
| gear |  | 1 |  |
| onerow |  | 1 |  |

## 0-6-1-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| armor |  | 1 |  |
| daggers |  | 1 |  |
| names-all |  | 1 |  |
| names-weapons |  | 1 |  |
| names |  | 2 |  |
| staves |  | 1 |  |
| typed |  | 1 |  |
| words |  | 1 |  |

## 0-6-build-4

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| buybar |  | 1 | One thing on this screenshot that I noticed, we need a rule that no matter where we are displaying silver, copper, gold, we need to use the correct colors for the S, the C, and the G. If you look in the button on this photo, it's not that way. So we need that as a global enforcement. |
| classic | pass | 2 | It should be called theme, not look. Seems like its working fine. |
| menu | fail | 4 | Tooltip stuff is good. Bid row setting is probably broken, but im not sure how its supposed to work. With this bid price option, does the stack option even make any sense? How, I don't even know how the new auction house works well enough. Like, I understood how this worked when every listing was like its own individual thing, stack size and all. Nowadays, I have no idea how this bid system would work at all. |
| open |  | 1 |  |
| table |  | 1 |  |
| tabs | pass | 1 | This test ran well. This is the first time Sniper's populating results with the reason being like unusually low priced. Are you able to test if this data is accurate or am I going to have to do it with tests? |

## 0-6-build-5

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| buybutton | pass | 1 |  |
| classicbuttons |  | 2 |  |
| recipe |  | 1 |  |
| settings | pass | 2 |  |
| sniper | pass | 1 |  |

## 0-6-build-10

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| fresh |  | 1 |  |
| ofusual |  | 1 |  |

## 0-7-1-1-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| buy | pass | 1 |  |
| buyout-only |  | 1 |  |
| gear-copper |  | 2 | I attempted to post that for the price you saw: 10 silver, 50 copper, and then this is what it posted for. |
| sniper | pass | 1 |  |
| type-below |  | 3 |  |
| type-early |  |  | I cant even move that fast, its extremely hard to do |
| undercut-typed |  | 2 |  |
| wait-listings |  |  | its so incredibly fast, i cant even tell |

## 0-7-1-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| cancel |  | 1 |  |
| classic |  |  | I can't test this. You had me cancel them. |
| copper |  |  | Return is: true |
| item-shown |  | 6 | On this one, I gave you a bunch of different screenshots. I even noticed in the Blizzard UI when I was posting the ritual bans: if I picked a 2-hour time, it was a silver. If I picked an 8-hour time, it was a silver, but then when I picked 24 hours, it went up. I just gave you a ton of info here. |
| name |  | 2 |  |
| ore-shown |  | 4 | I am including my amount of gold so you can see, you will see 4 screenshots:  - One screenshot before I post on auxForever - One screenshot after I posted on auxForever - One screenshot before I posted on Blizzard UI - One screenshot after I posted on Blizzard UI  Be careful here because I think I may have coincidentally picked a trade good that posts for a deposit of exactly 1 silver at a stack of 20. You may need to double-check with math in the code. |
| q-branch |  |  | Delete |
| q-comment |  | 1 |  |
| q-fb008 |  |  | Forget that, lets move on |
| q-profit |  |  | I dont really understand what you are asking |
| q-replies |  |  | No, forget about this too, its not a big deal |
| q-setting |  |  | I don't understand what you're asking me. I don't want to build it in yet. Let's just keep it how it is: it's always match lowest unless they change to undercut. If they do change to undercut once, though, let's... okay.  Let me paint a scenario for you. A player goes up to the auction house. For some reason, I can't control their actions or their desires. They want to undercut on every post they do. They have a ton of stuff to post. They set it to undercut.  Once they set it to undercut, it should just stay on undercut for all the things that they want to post, unless they close the auction house and open it back up. If they set it to undercut, I want it to stay at undercut until they close the auction house. Is that how it works now? |
| q-single |  |  | c |
| q-theme |  |  | No |
| q-waylaid |  |  | Forever does have waylaid crates. Do I need to buy one, and how much work is that to build in? We could plan that for 0.8. |
| rows |  | 1 |  |
| startmode |  | 2 | I didn't change anything here. I just did what you asked. I selected Undercut, closed the Auction House, opened it back up, and then took a screenshot. |

## 0-7-1-build-3

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| check |  | 3 |  |
| classic |  | 1 |  |
| listed |  | 1 |  |
| mine |  | 2 |  |
| settings |  | 1 |  |
| undercut | pass |  |  |

## 0-7-build-4

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| api |  | 1 |  |
| classic |  | 1 |  |
| columns |  | 2 |  |
| general |  |  | Is the API active and working??? |
| small | pass |  |  |
| sort |  | 2 |  |

## 0-8-build-1

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| general |  |  | As far as testing the controller, I'll leave that up to users who actually use controller mode to post issues. We're just going to assume it works until someone reports that it doesn't. I don't want to test with a controller. If you see any issue with that, let me know. |
| mouse-popup | skip |  |  |
| mouse-post | skip |  | Let's do this later after we implement the by the way crate stuff. |
| pad-buy | skip |  |  |
| pad-close | skip |  |  |
| pad-open | skip |  |  |
| pad-post | skip |  |  |

## 0-8-1-build-1

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| blizzard-ui | pass |  |  |
| cloak-exact |  | 1 |  |
| other-exact |  | 1 |  |
| professions | fail | 2 | if I do this, the screenshots are what happens. If I close and then open the professions window it starts on the left then teleports to its custom position set by me.k |
| profit-hover |  |  | What? |
| profit-line |  | 1 |  |
| profit-none | skip |  |  |

## 0-8-1-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| own-spot | pass |  |  |
| profit-none |  |  | This is way harder to solve than you think. I dont think I have a single item that aux didnt already fullscan. |
| reopen | pass |  |  |

## 0-8-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| crate-bags | skip |  |  |
| crate-recent |  | 1 |  |
| crate-search |  | 1 |  |
| crate-shift |  | 1 |  |
| crate-tooltip |  | 1 |  |
| mouse-post |  | 1 |  |

## 0-8-2-1-build-4

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| bids-buttons | skip |  |  |
| debug-lines |  | 2 |  |
| fullscan-time |  | 2 |  |
| gamepad-fight | skip |  |  |
| memory-line |  | 1 | Not sure what was supposed to happen here |
| post-inf |  | 1 |  |
| post-leave | skip |  |  |
| post-one |  | 1 |  |
| search-full |  | 2 | I had to close this error |
| search-typing | pass |  | Why dont we have tab completes working here? Is this something you can log as feedback and provide opus the correct way to do it? |
| sniper-rounds |  | 2 |  |

## 0-8-2-1-build-7

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| buy-one-click |  | 1 |  |
| copper-gear |  | 3 |  |
| crate-switch |  | 1 |  |
| ending-stat |  | 2 |  |
| fullscan-smooth |  |  | smooth |
| linen-all |  | 1 |  |
| live-many |  | 1 |  |
| many-sellers |  | 1 | I dont know if this worked, I couldnt even unfurl linen belt but I could linen bag |
| tab-key |  | 1 | it filled in the vanished part when I pressed tab |
| undercut-gear |  | 2 |  |

## 0-8-2-2-build-1

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| confirm-gear |  | 1 |  |
| confirm-trade |  | 2 |  |
| no-double | pass |  | Did you code in a manual wait time? If so I dont like that. Exlpain how you did this fix. |
| post-bid-on | pass |  |  |
| setting | pass | 1 |  |
| starts-at-1 | pass |  |  |

## 0-8-2-2-build-2

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| deals-still | pass |  |  |
| debug-list |  |  | This command isnt returning anything at all |
| live-2s | pass |  |  |
| rest-half |  |  | It still feels too long |
| round-time |  | 1 |  |

## 0-8-2-build-5

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| full-scan |  | 2 | I had to stop sniper for full scan to ungrey |
| general |  | 1 | I dont want to put shift instructions in the tooltip |
| shift-hint |  | 1 |  |
| sniper-buy |  |  | I find it very jarring that we stop the entire search when someone highlights something. We only did that to stop the lines from moving but I know there is a better way to do it without stopping the entire search.  Perhaps we get consensus with Gemini, in handoff |
| sniper-deals |  | 1 |  |
| tooltip-search | fail | 2 | This isnt returning items and there is a weird visual bug on % Hist Value |
| usually-switch |  | 2 |  |

## 0-8-2-build-7

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| crafting-percent |  | 1 |  |
| full-scan |  | 3 | it seems to have resumed as well, these screenshots were in sequence with no manual intervention |
| no-shift-hint |  | 2 |  |
| sniper-gear-holds |  | 1 |  |
| sniper-material |  | 1 |  |
| sniper-row-stays | pass |  | But when my row is frozen I can hear sounds like new entries should be popping up but they dont show up until I unselect the material I was "holding" |
| sort-arrow |  | 1 | k |
| tooltip-search |  | 1 | That was LIGHTNING fast |

## 0-8-2-build-8

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| general |  |  | [Someone Tyler knows, details removed] also reported his full scan wasnt working. Did we push some sort of update that may have corrupted the data? |
| sniper-new-rows | pass | 1 |  |

## 0-8-build-3

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| gear-auctions |  | 2 | ??? |
| gear-bag-list |  |  | I think we failed this |
| gear-post-price |  | 1 |  |
| gear-tooltip |  | 3 |  |
| mouse-post |  | 1 |  |

## 0-8-build-4

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| gear-names |  | 1 |  |
| general |  | 4 | This shows no results, but here is what it looks like when I search it.... something is wrong... |

## 0-8-build-5

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| agility |  | 3 | This makes no sense the numbers dont add up, something is still wrong. |
| general |  |  | Do whatever research and testing you need to now, [personal detail removed] Looks like we found our first real issue that you couldnt one-shot. |
| whale |  | 2 | Okay there isnt any of the whale when I search, but we need to give them a price to post at anyway. |

## 0-8-build-7

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| general |  | 1 | It's really bothering me that we are listing the same items for the same price in four different lines. Look at the top of this picture that I sent. You have four Merc Swords of Healing: 10 for sale, 2 for sale, 39 for sale, 5 for sale. I'm trying to understand: are there really only four sellers of these four lines? Why are we separating these lines?  Look at the 12 silver buyouts: we have them in two lines, even though they're the same price. I'm confused. I think this may be what happens when you move an add-on from one version of the auction house to the other, and I need to figure out the best way to move forward. |
| healing |  | 2 | Loading the post took quite a long time, do we have room to optimize there? |
| loads | pass | 2 |  |
| saved | pass |  |  |
| whale |  |  | Its a new version of the game claude I dont have the same items, there has been a large time skip in this chat |

## 0-8-build-8

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| fast | pass |  |  |
| suggest | skip |  |  |

## 0-8-build-9

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| auctions-rows |  | 1 |  |
| buy | pass |  |  |
| general |  | 1 | Next: tell Claude "Check the handoff." |
| post-rows |  | 1 |  |
| search-rows |  | 1 |  |

## 0-8-build-10

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| buybar |  | 1 |  |
| sellers |  | 1 |  |
| sniper |  | 1 |  |

## 0-8-build-12

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| cancel-color | pass |  |  |
| empty |  | 1 |  |

## 0-8-build-13

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| crates |  | 2 |  |
| help |  | 1 |  |
| sorts |  | 4 |  |
| stopped |  |  | I cant move my hand that fast |
| value |  | 1 |  |

## 0-8-build-14

| Step | Result | Screenshots | Note |
| --- | --- | --- | --- |
| crates-bags |  | 1 |  |
| crates-results |  | 3 |  |
| forsale |  | 1 |  |
