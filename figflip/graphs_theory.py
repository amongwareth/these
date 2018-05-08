import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import texfig


def K1(n, g, w, dwt, l, coef):
    dterm = 4 * g * (1 + coef * dwt / w)
    numerator = n * np.sqrt((dterm + l + n)**2 - 4 * n + 4) - (n - 2) * (dterm + l + n)
    denominator = 2 * (dterm + l + 2 * n)
    return numerator / denominator


def K2(n, g, w, dwt, l, coef):
    k1 = K1(n, g, w, dwt, l, coef)
    numerator = l * (n - 1) + k1 * (l + n)
    denominator = (l + n) * (n - 1) + k1 * (l + 2 * n)
    return numerator / denominator


def supply(xval, n, g, theta, w, dwt, l, coef):
    slope = (1 / K1(n, g, w, dwt, l, coef) - 1) / n
    print(slope)
    offset = theta / n * (1 - K2(n, g, w, dwt, l, coef) / K1(n, g, w, dwt, l, coef))
    return slope * xval + offset


n = 3
g = 10
l = 0.1
start = 0
end = 25
theta_l = np.sin(np.arange(start, end) / 24 * 2 * np.pi) / 40 + 2
w_l = 3 * (np.sin(np.arange(start, end) / 24 * 2 * np.pi) + 1.1)
dwt_l = theta_l[1:] - theta_l[:-1]
theta_l = theta_l[:-1]
w_l = w_l[:-1]
coef = 100

fig, ax1 = texfig.subplots()
# These are in unitless percentages of the figure size. (0,0 is bottom left)
width = 0.3
offset = 0.18
left, bottom, width, height = [offset, 1 - width - offset, width, width]
ax2 = fig.add_axes([left, bottom, width, height])
xval = np.arange(0, 2, 0.5)
idx = 3
w = w_l[idx]
theta = theta_l[idx]
dwt = dwt_l[idx]
ax1.plot(xval, supply(xval, n, g, theta, w, dwt, l, coef))
ax2.plot(np.arange(start, end)[:-1], theta_l, 'b')
ax2.plot(np.arange(start, end)[:-1], theta_l + w_l, 'r')
ax2.plot(np.arange(start, end)[:-1], theta_l - w_l, 'r')
plt.axvline(x=np.arange(start, end)[:-1][idx])
plt.show()

xval = np.arange(0, 2, 0.5)
for w, dwt, theta in zip(w_l, dwt_l, theta_l):
    plt.plot(xval, supply(xval, n, g, theta, w, dwt, l, coef))
plt.show()
