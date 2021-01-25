import pure_pynacl
import operator

zerobytes = 32

def encrypt(message, nonce, secret_key):
	msg = [0] * zerobytes
	
	for i in range(len(message)):
		msg.append(ord(message[i]))
		
	ciphertext = [0] * len(msg)

	pure_pynacl.crypto_secretbox_xsalsa20poly1305_tweet(ciphertext, msg, len(msg), nonce, secret_key)

	return ciphertext


secret_key = [252, 225, 194, 245, 50, 74, 200, 62, 171, 0, 232, 145, 225, 127, 41, 81, 81, 251, 42, 168, 34, 184, 60, 137, 168, 122, 88, 68, 189, 219, 123, 112]

nonce = [147, 3, 123, 195, 76, 217, 196, 102, 214, 10, 144, 88, 23, 135, 163, 60, 46, 86, 20, 249, 39, 70, 110, 205]


msg1 = "This is a secret message!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
msg2 = "***************************More secret stuff here***"

ciphertext1 = encrypt(msg1, nonce, secret_key)
ciphertext2 = encrypt(msg2, nonce, secret_key)

xor_cipher = []
for i in range(len(ciphertext1)):
    xor_cipher.append(operator.xor(ciphertext1[i], ciphertext2[i]))


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

