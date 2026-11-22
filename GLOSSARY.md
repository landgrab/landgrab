# Landgrab

Landgrab lets people subscribe to individual What3Words squares of land ("tiles"), for themselves or as a gift, and lets admins keep subscribers updated about the land they support.

## Land

**Project**:
A conservation or rewilding initiative, managed independently of other projects (with its own stakeholders and landowners), that owns a set of plots and offers prices.
_Avoid_: Campaign, site

**Plot**:
A named, bounded area of land within a project, made up of tiles.
_Avoid_: Parcel, field, area

**Tile**:
A single What3Words square of land within a plot, which can belong to only one subscription at a time.
_Avoid_: Square, lot, parcel

**What3Words address**:
The three-word identifier of a tile's square (written `///a.b.c`).
_Avoid_: W3W code, location

**Available tile**:
A tile with no current subscription, or whose latest subscription has been cancelled, so anyone can take it.
_Avoid_: Free tile, unclaimed tile

**Unavailable tile**:
A tile whose latest subscription has not been cancelled, so no one else can take it.
_Avoid_: Taken tile, claimed tile, redeemed tile

## Subscribing

**Subscription**:
A recurring Stripe payment for one tile in a project, paid by a subscriber and enjoyed by a redeemer.
_Avoid_: Membership, purchase, order

**Subscriber**:
The user who pays for a subscription.
_Avoid_: Buyer, customer, payer

**Redeemer**:
The user who enjoys a subscription's tile; either the subscriber themselves or the person they gifted it to.
_Avoid_: Recipient, giftee, holder, owner

**Redeem**:
To become the redeemer of a subscription, either by redeeming your own or by accepting a redemption invite.
_Avoid_: Claim, accept

**Gifted tile**:
A tile whose usable subscription a user pays for while someone else redeems it.
_Avoid_: Given tile, present

**Referred tile**:
A tile whose usable subscription is paid for by one of a user's referees, whoever redeems it.
_Avoid_: Referral tile, referee tile

**Choose a tile**:
The step where a redeemer picks an available tile for a usable subscription that has no tile yet.
_Avoid_: Claim, link, assign, allocate

**Gift**:
A subscription whose subscriber and redeemer are different users. Whether a subscription is meant as a gift can be chosen at checkout.
_Avoid_: Present, gift subscription

**Redemption invite**:
A tokenised link a subscriber shares with a gift recipient so they can redeem the gift.
_Avoid_: Gift link, claim link

**Price**:
A project's offered subscription option, with a title, a displayed amount and a Stripe price.
_Avoid_: Plan, tier, product

**Promo code**:
A code applied at checkout that either gives a Stripe discount or starts a free trial.
_Avoid_: Coupon, voucher, discount code

**Free trial**:
A card-free introductory period granted by a promo code, after which an unpaid subscription is paused.
_Avoid_: Trial period

**Usable subscription**:
A subscription that currently entitles its redeemer to a tile, meaning it is active or in a free trial.
_Avoid_: Valid subscription, live subscription

## Updates

**Post**:
An admin-written update, optionally published at a set time, shown to the users who may view it.
_Avoid_: Article, news item, update

**Postable**:
A tile, plot, project or team that a post is attached to; a post is viewable by users connected to any of its postables.
_Avoid_: Target, tag

**Comment**:
A user's reply on a post, which may be public or private.
_Avoid_: Reply, message

## People

**User**:
A registered person who can subscribe to tiles, redeem gifts, view posts and comment.
_Avoid_: Member, account

**Admin**:
A user who manages projects, plots, tiles and posts.
_Avoid_: Staff, moderator

**Team**:
An organisation that groups users, with its own team page; posts can be attached to it and its team tiles are shown together on a map.
_Avoid_: Organisation, group, company

**Team tile**:
A tile redeemed by a member of a team through a usable subscription.
_Avoid_: Team land, group tile

**Referrer**:
The user who brought another user to Landgrab, either through their referral link or by gifting them a subscription they redeemed.
_Avoid_: Inviter, affiliate

**Referee**:
A user who has a referrer; each user has at most one, fixed when they first sign up via a referral link or redeem a gift.
_Avoid_: Referral, invitee, recruit
