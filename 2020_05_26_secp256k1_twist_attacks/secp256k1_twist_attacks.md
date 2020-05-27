# Dangers of using secp256k1 for encryption - Twist Attacks

*Christian Lundkvist, 2020-05-26*

In this post we will highlight some issues when using the elliptic curve secp256k1 (popular in cryptocurrencies like Ethereum & Bitcoin) for encryption.

Cryptography experts have long warned that there are pitfalls in doing this, for instance here is a [Twitter thread](https://twitter.com/pbarreto/status/825703772382908416?s=21) from 2013 (revived in 2017) where Paulo Barreto discusses insecure aspects of the secp256k1 curve related to this article.

The core of the attack described here uses the ability for an attacker to give the victim a specific choice of "public key" (chosen curve point) and ask them to encrypt a message to that curve point. When doing this the victim can reveal information about their private key, and if they get tricked into performing a number of such encryptions the attacker can recreate the victims private key out of this information.

## Quick intro to Elliptic curves

An [Elliptic Curve](https://en.wikipedia.org/wiki/Elliptic_curve) is defined as the pairs of numbers (integers in our case) `(x,y)` that satisfy an equation of the form

```
y^2 = x^3 + c1*x + c2
```

for specific values of the coefficients `c1`, `c2`. We are specifically interested in the case where the above equation is modulo a prime number `p` (for technical reasons `p` should be larger than 3).

As an example in the context of Bitcoin and Ethereum, when we talk about the curve secp256k1 we mean the elliptic curve with `c1=0` and `c2=7`, i.e. the equation

```
y^2 = x^3 + 7
```

when computed modulo `p`, where `p` is the large prime number

```
p = 115792089237316195423570985008687907853269984665640564039457584007908834671663.
```

We can define an "addition" operation on the points of an elliptic curve which is described visually as follows: Take two points `P`, `Q`. If the two points are different, take the line between the two points, intersect this line with the curve, then draw a vertical line through the intersection point. The point `P+Q` is defined as the intersection of this vertical line with the curve.  If we are adding a point with itself, i.e. `P+P = 2P` we instead take the tangent line to the curve, take the intersection of the tangent line with the curve, then take the vertical line as before.

![](https://github.com/christianlundkvist/blog/blob/master/2020_secp256k1_twist_attacks/files/1024px-ECClines.svg.png?raw=true)

If we compute the algebraic expression of the point `P+Q` we note that the constant `c2` is not used at all during the computation. We will come back to this later on.

## Public and private keys

Since we have defined addition of curve points we can define multiplication by an integer. Suppose `P` is a point of an elliptic curve and `n` is an integer. Then we define the multiplication `n*P` as

```
n*P = P + P + ... + P (n terms in the sum).
```

When used in elliptic curve cryptography, we select a specific point on the elliptic curve (often denoted `G`) to be used for the calculations. When computing a public/private key pair we first select a random number `s` satisfying `0 < s < p`.

We then compute the corresponding public key as the curve point `P = s*G`. If the curve and base point `G` are chosen correctly we can share the public key `P` freely without risking the private key `s` being known.

The fact that it's hard to compute the number `s` given the point `P` is called the [discrete logarithm](https://en.wikipedia.org/wiki/Discrete_logarithm) problem and it's the foundation for the security of elliptic curve cryptography.

## Diffie-Hellman Key Exchange

We can use public and private keys to encrypt messages between two actors. Suppose Alice has a private key `a`, with a corresponding public key `A = a*G`, and suppose Bob has a private key `b` with the corresponding public key `B = b*G`. 

Then Alice can send a secret message to Bob in the following way:  Alice takes Bobs public key `B` and computes the point 

```
 S = a*B = a*bG
```

on the curve. She can then use the data of `S` as an encryption key for a symmetric cipher like [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard), and send the ciphertext to Bob.

Bob in turn will take Alices public key `A` and compute the point

```
b*A = b*a*G = a*b*G = a*B = S
```

so Bob will compute the same point `S` as Alice. Bob can then use this key to decrypt Alices coded message. The point `S` is called a *shared secret*.

## Group structure and the small subgroup attack

The addition operation described above defines a [group structure](https://en.wikipedia.org/wiki/Group_(mathematics)) on the points of an elliptic curve. Suppose we have an elliptic curve where the corresponding group of points `E` has a [subgroup](https://en.wikipedia.org/wiki/Subgroup) `H` with few elements (say a few billion) and assume that the number of elements in the subgroup is a prime. The number of elements of a group is called the *order* of the group.

Suppose Bob has a private key `b` that Alice wishes to learn something about. She can take a point `P` in the subgroup `H` (this point is not a public key corresponding to any particular private key, but there is no way for Bob to know this) and tell Bob that this is her public key and can Bob please send an encrypted message to her.

Bob will compute what he thinks is a shared secret `Q = b*P`. He will use the data in `Q` to encrypt a message to Alice and send her the encrypted message `C`.

Since Alice knows that the point `Q` is in the group `H` (and `H` has a small number of elements) she can attempt to brute-force decrypt the message `C` with the points

```
P, 2*P, 3*P, 4*P, ...
```

etc until the decryption succeeds. Suppose the decryption succeeds at `k*P`. She then knows that `Q = k*P` and also `Q = b*P` so Alice has now learned that `k = b mod q`, where `q` is the number of elements (i.e. the order) of the subgroup `H`.

Thus Alice was able to get information about Bobs private key by giving him a maliciously chosen curve point.

This specific attack on Bobs private key will not work as described for the elliptic curve secp256k1 since the number of elements of the group is a prime number. By [Lagrange's Theorem](https://en.wikipedia.org/wiki/Lagrange's_theorem_(group_theory)) this means that there are no non-trivial subgroups to this group.

## Twist attacks on secp256k1

We can make a slight modification to the small subgroup attack mentioned above by having Alice choose a point on a modified curve.

The way she does this is as follows: Instead of using the secp256k1 curve defined by

```
y^2 = x^3 + 7
```

she uses a curve with a different constant term, for instance the curve `E2` defined by

```
y^2 = x^3 + 2.
```

Unlike the original secp256k1 curve this new curve will have some small subgroups and Alice can pick a point `P` in one of them and give to Bob. Recall in our discussion on elliptic curve addition and multiplication that the algebraic operations of addition and multiplication are not actually using the constant term of the curve.

If Bob has a naive implementation of the elliptic curve multiplication (`Q = b*P`) that does not check if `P` is actually on the secp256k1 curve (which it isn't) then his software will instead perform the computation on the curve `E2`, and Alice can perform the small subgroup attack described above.

## Chinese Remainder Theorem and details of the Twist attack

We have seen above how Alice can launch a Twist attack against Bob, and in this section we will show how to implement this using the mathematical software package Sage.

We will first illustrate in detail how Alice can obtain the number `b` mod `q` where `b` is Bobs private key and `q` is a small prime.

First of all, we use Sage to set up the curve used in the attack, get the curve group and a generator of the group. Then we check the order of the group (i.e. the number of elements) and factor that number to look for smaller subgroups:

```
p = 115792089237316195423570985008687907853269984665640564039457584007908834671663
E = EllipticCurve(GF(p), [0,2])
Grp = E.abelian_group()
g = Grp.gens()[0]
numElements = g.order()
print( "{0} = {1}".format(numElements, factor(numElements)) )
```

We see that the number of elements of the group can be factored as

```
38597363079105398474523661669562635951234135017402074565436668291433169282997 = 3 * 13^2 * 3319 * 22639 * 1013176677300131846900870239606035638738100997248092069256697437031
```

Since one of the factors is 3319, we can find a subgroup of the above group `Grp` that has 3319 elements. To find a generator of this subgroup we use the [Chinese Remainder Theorem](https://en.wikipedia.org/wiki/Chinese_remainder_theorem). This theorem says the following: Suppose we have a decomposition of an integer `n` as

```
n = n1 * n2 * ... * nm
```

where `n1`, `n2` etc are pairwise coprime. Then the function

```
x --> (x mod n1, x mod n2, ..., x mod nm)
```

from `ZZ/(n)` to `ZZ/(n1) x ... x ZZ/(nm)` is an isomorphism, where `ZZ/(n)` denotes the group of integers modulo the integer `n`. This means that for every tuple of non-negative integers 

```
x1, x2, ... xm with x1 < n1, x2 < n2, ..., xm < nm
```

there is a unique integer `x < n` such that
 ```
x1 = x mod n1, x2 = x mod n2, ..., xm = x mod nm.
```

In this particular case we have
 ```
n1 = 3
n2 = 13*13
n3 = 3319
n4 = 22639
n5 = 
1013176677300131846900870239606035638738100997248092069256697437031
```

and we note that the element `(0, 0, 1, 0, 0)` generates a group of order 3319 in the group

```
ZZ/(n1) x ZZ/(n2) x ZZ/(n3) x ZZ/(n4) x ZZ/(n5).
```

  Using the Chinese Remainder Theorem in Sage we get the corresponding element of the elliptic curve group, which is then a generator of a subgroup of order 3319:

```
x = crt([0,0,1,0,0], [n1,n2,n3,n4,n5])
print(x)
P = x*g
print(P)
print(P.order())
```

Alice can now give the point P to Bob, he will compute the "Shared secret" from P and his private key `b`:

```
Q = b * P
```

Bob takes `Q` and encrypts a message to Alice:

```
cipherText = encrypt(Q, "Hello")
```

Since Alice knows that the point `Q` that Bob computed is in the subgroup generated by the point `P`, she can brute-force `Q` as follows:

```
y = 0
for i in range(1, 3319):
  if key_does_decrypt(i*P, cipherText):
    y = i
```

This way Alice successfully computes a number `y < 3319` such that `y*P = Q`, and so we have `y = b mod 3319`. This is a way that Alice can reveal some data about Bob's private key `b`. In the next section we show how to recreate Bob's entire private key by doing this Twist attack for a number of different small subgroups.

Note that the functions `encrypt` and `key_does_decrypt` in the Sage file are dummy functions and are for illustration purposes only. The reader is free to implement them using a real encryption library and the general algorithm would remain the same.

## Recreating Bobs private key

In the previous section we illustrated how Alice can select an elliptic curve with a different constant than the Ethereum curve, choose a generator of a small subgroup on that curve and use that to compute Bobs private key modulo the order of that subgroup.

Suppose Alice does this for a number of different subgroups with orders

```
n1, n2, ..., nm
```

which are coprime, such that their product is larger than 2^256. Then by using the Chinese Remainder Theorem she can recreate Bobs private key in full.

To do this we will consider the following curves:

```
E1: y^2 = x^3 + 1
E2: y^2 = x^3 + 2
E3: y^2 = x^3 + 3
E4: y^2 = x^3 + 4
E6: y^2 = x^3 + 6
```

Each of these curves have subgroups of small orders. We list the orders of these subgroups:

```
E1: 20412485227
E2: 3319, 22639
E3: 109903, 12977017, 383229727
E4: 18979
E6: 10903, 5290657, 10833080827, 22921299619447
```

Note that the subgroup of `E2` of order 3319 is the one we used in our example in the previous section.

For each of the above elliptic curves, we compute generators of the corresponding subgroups in the same way as in the previous section. This is done in the file [compute_low_order_generators.sagews][compute_gens]. We obtain 11 generators, for instance `P32` denotes the generator of the second subgroup of `E3`:

```
P11, P21, P22, P31, P32, P33, P41, P61, P62, P63, P64.
```

Once we have the generators (eleven of them) Alice can give a generator to Bob who will compute the shared secret of that generator. In the code it looks like this:

```
Q11 = b * P11
Q21 = b * P21
Q22 = b * P22
Q31 = b * P31
Q32 = b * P32
Q33 = b * P33
Q41 = b * P41
Q61 = b * P61
Q62 = b * P62
Q63 = b * P63
Q64 = b * P64
```

 Once Alice has the shared secrets (`Q11, Q21, Q22, ...`) she can use them to compute Bobs private key. Note that in a real attack Bob would give Alice encrypted messages  (`C11, C21, C22, ...`) but as we saw in the previous section Alice can brute force those messages to find the keys that decrypts them. These decryption keys would be the shared secrets `Q11, Q21, Q22`, etc.

In the code [recover_private_key.sagews][recover_key] we use the Sage function `discrete_log_rho` to compute the [discrete logarithm](https://en.wikipedia.org/wiki/Discrete_logarithm) of a shared secret `Q` with respect to a basepoint `P`. What this means is that we can compute an integer `x11` such that `Q11 = x11*P11`, an integer `x21` such that `Q21 = x21*P21` etc.

As explained in the previous section this means that we have now computed the following regarding Bob's private key `b`:

```
x11 = b mod 20412485227
x21 = b mod 3319
x22 = b mod 22639
x31 = b mod 109903
x32 = b mod 12977017
x33 = b mod 383229727
x41 = b mod 18979
x61 = b mod 10903
x62 = b mod 5290657
x63 = b mod 10833080827
x64 = b mod 22921299619447
```

Since the product of all the group orders are larger than 2^256 we can now use the Chinese Remainder Theorem again to completely recreate Bob's private key `b` from the above values:

```
x = crt([x11, x21, x22, x31, x32, x41, x61, x62, x63, x64], [20412485227, 3319, 22639, 109903, 12977017, 383229727, 18979, 10903, 5290657, 10833080827, 22921299619447])

print(x == b)
```

## Summary & mitigations

We've shown that if Bob has a problematic implementation of elliptic curve encryption using the curve secp256k1 then Alice can steal Bob's private key by giving him a number of maliciously chosen curve points and having Bob encrypt messages using those curve points.

For instance, using a simple Sage function like

```
def compute_shared_secret(myPrivateKey, theirPublicKey):
    return (myPrivateKey * theirPublicKey)
```

will be susceptible to this attack. Also implementing the elliptic curve multiplication algebraically without first confirming that the point is on the correct curve will be vulnerable to the attack.

How can Bob protect himself? In order to protect against this attack one needs to make sure to not compute elliptic curve multiplication on another curve than secp256k1. We can do either of the following:

* Do a verification that the curve point we are about to multiply is actually on the correct curve, by verifying that the equation is fulfilled.
* Require use of compressed public keys. These are curve points represented not by a pair of integers `(x, y)` but instead by the number `x` along with a one-bit value that allows us to compute the number `y` using the curve equation. This makes the public key shorter and since we need to use the curve equation to get the complete point we can be sure that we are not using a different curve.
* Use a different curve for encryption like curve25519 which has a robust implementation that is not vulnerable to this attack.

## Example code

The reader can find the Sage code implementing the above computations at the following links:

Detailed example of Twist attack:

[single_twist_attack.sagews][single_twist]

Computing the generators for the low-order groups:

[compute_low_order_generators.sagews][compute_gens]

Recovering the private key:

[recover_private_key.sagews][recover_key]

In order to run the example code, download [Sage](https://sagemath.org) or create an account at [CoCalc](https://cocalc.com) in order to run the examples in a browser.


[single_twist]: https://github.com/christianlundkvist/blog/blob/master/2020_secp256k1_twist_attacks/files/single_twist_attacks.sagews
[compute_gens]: https://github.com/christianlundkvist/blog/blob/master/2020_secp256k1_twist_attacks/files/compute_low_order_generators.sagews
[recover_key]: https://github.com/christianlundkvist/blog/blob/master/2020_secp256k1_twist_attacks/files/recover_private_key.sagews

