# Checkout

The checkout process supports a user in buying a subscription.

Checkout relies on the user being authenticated in the app first;
they go to view any tile and can click the "subscribe" button
to subscribe to that tile.

As a pre-requisite, on arrival at the `checkout` page, we will
synchronously ensure that the user has been set up as a
customer on Stripe (see `StripeCustomerCreateJob`).

We'll set up a Stripe checkout session associated to the tile,
and render the checkout form via Stripe's JS SDK.

Refer to the [Stripe Embedded Checkout docs](https://docs.stripe.com/checkout/embedded/quickstart).

After checkout completes, the user is returned to the
`checkout_success_path` (with the `{CHECKOUT_SESSION_ID}`
template variable substituted by Stripe), and the subscription is
retrieved and its status checked.

The user is redirected to the tile or project page, as appropriate.
They will subsequently be prompted to claim the chosen tile,
or any other within the project.

Payment failure simply results in returning the user to checkout to retry.

## Free trials without a card

A `PromoCode` with `free_trial_days` set (and no `stripe_id`) turns the checkout
link into a card-free trial: `/checkout/checkout?price=<price>&code=<code>`.

The checkout session is created with `payment_method_collection: 'if_required'`,
`subscription_data.trial_period_days`, and
`trial_settings.end_behavior.missing_payment_method: 'pause'`, so the customer
isn't asked for card details and the subscription is paused (Stripe status
`paused`) if no payment method has been added when the trial ends.
See the [Stripe docs](https://docs.stripe.com/payments/checkout/free-trials#free-trials-without-payment-method).

Create one from the Rails console: `PromoCode.create!(code: 'FREETRIAL', free_trial_days: 14)`.
