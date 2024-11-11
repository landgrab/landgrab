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
