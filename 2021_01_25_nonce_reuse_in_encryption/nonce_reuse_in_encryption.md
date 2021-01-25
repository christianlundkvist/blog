# Nonce reuse in encryption - what’s the worst that can happen?

## Introduction

This post will discuss encryption and the role of the nonce therein, specifically what can happen if we reuse this number. We will focus on *symmetric encryption* meaning the system uses one secret key which is the same for encryption as for decryption. 

Modern encryption libraries like [nacl](nacl.cr.yp.to) have encryption interfaces similar to the following:

```
ciphertext = encrypt(plaintext, nonce, secret_key)
```

The user plugs in the plaintext to encrypt, the secret key and the nonce. The function returns the ciphertext (i.e. encrypted message).

To decrypt, the interface looks like this:

```
plaintext = decrypt(ciphertext, nonce, secret_key)
```

Here we need to plug in the same nonce as we used for encryption. This function returns the plaintext.

## The nonce

The word *nonce* is a mashup of the phrase “number used once” which implies that we are not supposed to reuse this number for different messages. For instance the [TweetNacl](https://github.com/dchest/tweetnacl-js#naclsecretboxmessage-nonce-key) javascript library has the following description of the encryption interface:

*Encrypts and authenticates message using the key and the nonce. The nonce must be unique for each distinct message for this key.*

The [nacl](http://nacl.cr.yp.to/secretbox.html) C library has the following passage describing the use of the nonce:

*Note also that it is the caller's responsibility to ensure the uniqueness of nonces. For example, by using nonce 1 for the first message, nonce 2 for the second message, etc. Nonces are long enough that randomly generated nonces have negligible risk of collision.*

So how bad is it to use the same nonce for two different messages? Sometimes breaking security recommendations are not fatal. For instance by messing up we might be reducing the strength of a specific algorithm from 256 bits to 128 bits. In this case however we will show that reusing the nonce between two different messages can lead to complete compromise of the plaintext of the messages.

## Demonstration of nonce reuse

We will demonstrate the dangers of nonce reuse by encrypting two different messages using the same nonce. The code is available in the file [nonce_reuse.py](https://github.com/christianlundkvist/blog/blob/master/2021_01_25_nonce_reuse_in_encryption/files/nonce_reuse.py). We use the library [pure_pynacl](https://github.com/jfindlay/pure_pynacl) for the encryption functionality.

Here are the two plaintext messages will we use:

```
msg1 = "This is a secret message!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
msg2 = "***************************More secret stuff here***"
```

We’ll use the following nonce and secret key that we randomly generated:

```
secret_key = [252, 225, 194, 245, 50, 74, 200, 62, 171, 0, 232, 145, 225, 127, 41, 81, 81, 251, 42, 168, 34, 184, 60, 137, 168, 122, 88, 68, 189, 219, 123, 112]

nonce = [147, 3, 123, 195, 76, 217, 196, 102, 214, 10, 144, 88, 23, 135, 163, 60, 46, 86, 20, 249, 39, 70, 110, 205]
```

Note that the `nacl` library use lists of 8-bit numbers (0-255) as secret keys and nonces. We encrypt the two messages using the same key and nonce:

```
ciphertext1 = encrypt(msg1, nonce, secret_key)
ciphertext2 = encrypt(msg2, nonce, secret_key)
```

We will now see how we can get information about the messages `msg1` and `msg2` using only `ciphertext1` and `ciphertext2`, i.e. we are not using `nonce` or `secret_key` at all. First we show how to extract this information and then explain what’s going on and how this method works.

First start by doing XOR between each character in the two ciphertexts and put the result in a new array `xor_cipher`:

```
xor_cipher = []
for i in range(len(ciphertext1)):
    xor_cipher.append(operator.xor(ciphertext1[i], ciphertext2[i]))
```

Next take the `xor_cipher` array and XOR each element in this array with one chosen ASCII character. Repeat this for each ASCII character `d` and print out each such string:

```
for d in range(32,127):
    xor_temp = []
    for i in range(len(xor_cipher)):
        xor_temp.append(operator.xor(xor_cipher[i], d))
    xor_str = ''

    for i in range(len(xor_temp)):
        if xor_temp[i] == 0:
            xor_str += ' '
        else:
            xor_str += chr(xor_temp[i])
    print(xor_str)
```

Let’s look at the printout from the above program and see if anything stands out:

![](https://github.com/christianlundkvist/blog/blob/master/2021_01_25_nonce_reuse_in_encryption/files/program_printout.jpeg?raw=true)

As we can see we have managed to completely extract both secret messages using only the ciphertexts! Clearly reusing the nonce can be completely catastrophic for the confidentiality of the messages.

## Explanation of above method

The core of the nacl encryption algorithm is similar to how a [one-time pad](https://en.wikipedia.org/wiki/One-time_pad?wprov=sfti1) works.

This is a very rough description of the algorithm: The nonce and the secret key are hashed together to create a random pad. The random pad is then XORed together with the cleartext message to create the ciphertext.

```
random_pad = Hash(secret_key, nonce)
for i in range(len(message)):
  ciphertext[i] = random_pad[i] XOR message[i]
```

By definition of the XOR operation we note that

```
0 XOR 0 = 0
0 XOR 1 = 1
```

and therefore by considering each bit separately we have

```
0 XOR x = x
```

for any 8-bit integer `x`. Furthermore we have

```
0 XOR 0 = 0
1 XOR 1 = 0
```

and so 

```
x XOR x = 0
```

for any 8-bit integer `x`.

Let’s see how this is connected to our encryption situation. In this case if we reuse the nonce it means that the random pad used for both ciphertexts are the same. When XORing the ciphertexts together we get:

```
for i in range(len(message)):
  xor_str[i] = ciphertext1[i] XOR ciphertext2[i]
```

From the properties of the XOR operator we have

```
ciphertext1[i] XOR ciphertext2[i] = (random_pad[i] XOR message1[i]) XOR (random_pad[i] XOR message2[i]) =
= (message1[i] XOR message2[i]) XOR (random_pad[i] XOR random_pad[i]) =
= (message1[i] XOR message2[i]) XOR 0 =
message1[i] XOR message2[i].
```

Thus we see that when XORing the two ciphertexts together the result is equal to simply XORing the clear text messages together, so we’ve completely bypassed the secret key.

In our particular case we’ve deliberately chosen our messages so that the effect is dramatic. Let’s see in detail what’s going on in our specific example.

In each row of the printout we take the string `ciphertext1 XOR ciphertext2` and XOR each character of the string with an ASCII character. Thus there will be less than 128 rows in the printout which is easy to go over manually.

As a concrete example, let’s look at the first four characters in the line that is XORed with the character `*` and see how the word “This” is extracted from the ciphertexts:

```
ciphertext1[0] XOR ciphertext2[0] XOR ‘*’ = (random_pad[0] XOR ‘T’) XOR (random_pad[0] XOR ‘*’) XOR ‘*’ = ‘T’ XOR ‘*’ XOR ‘*’ = ‘T’
ciphertext1[1] XOR ciphertext2[1] XOR ‘*’ = (random_pad[1] XOR ‘h’) XOR (random_pad[1] XOR ‘*’) XOR ‘*’ = ‘h’ XOR ‘*’ XOR ‘*’ = ‘h’
ciphertext1[2] XOR ciphertext2[2] XOR ‘*’ = (random_pad[2] XOR ‘i’) XOR (random_pad[2] XOR ‘*’) XOR ‘*’ = ‘i’ XOR ‘*’ XOR ‘*’ = ‘i’
ciphertext1[3] XOR ciphertext2[3] XOR ‘*’ = (random_pad[3] XOR ‘s’) XOR (random_pad[3] XOR ‘*’) XOR ‘*’ = ‘s’ XOR ‘*’ XOR ‘*’ = ‘s’
```

The reason that we can completely extract the word “This” and the other words of the message in `msg1` is that the corresponding characters in `msg2` are the same (in our case ‘*’).

For a general pair of messages `msg1` and `msg2` this will likely not be the case. However, even for general text messages you can gain a lot of information about the individual messages if you gain access to the XOR of the two messages, as we’ve done here.

## Summary

We’ve shown that if you reuse nonces between different encrypted messages you risk completely exposing your clear text messages. Thus, always make sure to use different nonces for different messages. The easiest way to do this is to randomly generate the nonces, since by doing this you don’t have to keep track of which ones you’ve used in the past. The space of possible nonces is big enough that randomly generating the nonces will make it virtually impossible that nonces are reused.