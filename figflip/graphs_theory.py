import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import texfig


def K1(n, g, w, dwt, l, coef):
    dterm = 4 * g * (1 + coef * dwt / (w / 3))
    # print('dwt', dwt / w)
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
    # print('slope', slope)
    offset = theta / n * (1 - K2(n, g, w, dwt, l, coef) / K1(n, g, w, dwt, l, coef))
    return slope * xval + offset


n = 3
g = 1
l = 0.1
idx = 5
coef = 1
ymin = []
ymax = []
rangem = 300
for i in range(rangem):
    start = 0 + i
    end = 24 + i
    theta_l = np.sin(np.arange(start, end) / 24 * 2 * np.pi) + 10
    w_l = (np.sin(np.arange(start, end) / 24 * 2 * np.pi) + 3)
    dwt_l = w_l[1:] - w_l[:-1]
    theta_l = theta_l[:-1]
    w_l = w_l[:-1]
    xval = np.arange(0, 3, 0.5)
    w = w_l[idx]
    theta = theta_l[idx]
    dwt = dwt_l[idx]
    yvals = supply(xval, n, g, theta, w, dwt, l, coef)
    ymin.append(yvals.min())
    ymax.append(yvals.max())
ysup = 1.1 * max(ymax)
yinf = 0.9 * min(ymin)

for i in range(rangem):
    print(i)
    start = 0 + i
    end = 24 + i
    theta_l = np.sin(np.arange(start, end) / 24 * 2 * np.pi) + 10
    w_l = (np.sin(np.arange(start, end) / 24 * 2 * np.pi) + 3)
    dwt_l = w_l[1:] - w_l[:-1]
    theta_l = theta_l[:-1]
    w_l = w_l[:-1]
    xval = np.arange(0, 3, 0.5)
    w = w_l[idx]
    theta = theta_l[idx]
    dwt = dwt_l[idx]
    yvals = supply(xval, n, g, theta, w, dwt, l, coef)

    fig, ax1 = texfig.subplots()
    # These are in unitless percentages of the figure size. (0,0 is bottom left)
    width = 0.3
    offset = 0.12
    offsetv = 0.05
    left, bottom, width, height = [offset, 1 - width - offsetv, width, width]
    ax2 = fig.add_axes([left, bottom, width, height])
    ax1.plot(yvals, xval, label=str(idx))
    ax1.set_ylim([xval.min(), xval.max()])
    ax1.set_xlim([yinf, ysup])
    # ax1.text((6 * ysup + yinf) / 7, 0.2, r'q')
    # ax1.text(yinf + 0.05, (xval.max() * 6 + xval.min()) / 7, r'p')
    # print('q', (ysup+yinf)/2, 0.2)
    # print('p', yinf - 0.15, (xval.max()+xval.min())/2)
    ax2.plot(np.arange(start, end)[:-1], theta_l, 'b')
    ax2.plot(np.arange(start, end)[:-1], theta_l + w_l, 'r')
    ax2.plot(np.arange(start, end)[:-1], theta_l - w_l, 'r')
    ax2.set_xlim([start, end])
    ax2.set_ylim([0, 1.1 * (theta_l + w_l).max()])
    # ax2.text((end + start) / 2, (theta_l + w_l / 1.5).max(), r'$\theta$')
    plt.axvline(x=np.arange(start, end)[:-1][idx])
    texfig.savefig('figs/test' + str(start))
    plt.close('all')
    # plt.show()


ax1.legend()
plt.show()


ax2.plot(np.arange(start, end)[:-1], theta_l, 'b')
ax2.plot(np.arange(start, end)[:-1], theta_l + w_l, 'r')
ax2.plot(np.arange(start, end)[:-1], theta_l - w_l, 'r')
plt.axvline(x=np.arange(start, end)[:-1][idx])
plt.show()
# texfig.savefig('test')


xval = np.arange(0, 2, 0.5)
for w, dwt, theta in zip(w_l, dwt_l, theta_l):
    plt.plot(xval, supply(xval, n, g, theta, w, dwt, l, coef))
plt.show()
