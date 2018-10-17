# -*- coding: utf-8 -*-
"""
Functionality to read NM files produced by DOTTER
"""

import scipy.io as sio
import numpy as np
from skimage import io


class reader():
    """Class to read NM files

    rdr = nmReader.reader()
    rdr.loadNM('001.nm')
    """

    nmFile = []
    N = []
    M = []
    channels = []
    nNuclei = 0

    def __repr__(self):
        ret = ""
        ret = ret + " -- NM reader --\n"
        if(len(self.nmFile) == 0):
            ret = ret + " -> No NM files loaded\n"
            return ret

        ret = ret + "NM file: {}\n".format(self.nmFile)
        ret = ret + "Channels:\n"
        for c in self.channels:
            ret = ret + " {}\n".format(c)
        ret = ret + "# Nuclei: {}\n".format(self.nNuclei)
        return ret

    def getNNuclei(self):
        """ tells how many nuclei there are in the NM file
        """
        return self.nNuclei

    def getUserDots(self, chan):
        """ Get userDots for specified channel number
        """
        # Get all user dots for this channel
        # channel defined by index in chan
        D = np.ndarray([0, 3])
        for nn in range(0, self.nNuclei):
            dots = self.N[0][nn][0]['userDots'][0][0][chan]
            D = np.concatenate((D, dots[:, 0:3]), axis=0)
        return(D)

    def getMetaDots(self, chan):
        D = self.M['dots'][0][0][0][chan]
        return(D)

    def getPatch(self, im, dt, side):
        """ Extract a 2D single patch from the image im encoded as a np.ndarray
        Uses the 0-indexed coordinate given by dt.
        The size of the patch will be [side x side]
        """
        s = (side-1)/2  # side = s+1+s
        s = int(s)
        dt = dt.round()
        dt = dt.astype('int')
        patch = im[dt[2], dt[0]-s:dt[0]+s+1, dt[1]-s:dt[1]+s+1]
        # import ipdb; ipdb.set_trace()
        return(patch.astype('float'))

    def getPatches(self, chan, D, side=5):
        """ Grab [side x side] large patches
        around the dots specified in D by x,y,z
        #  TODO: skip those close to boundary
        """
        im = io.imread(self.imfiles[chan])
        P = np.ndarray([0, side, side])
        for idx in range(0, D.shape[0]-1):
            d = D[idx, :]
            patch = self.getPatch(im, d-1, side)
            patch = np.expand_dims(patch, 0)
            P = np.concatenate((P, patch), axis=0)

        return(P)

    def loadNM(self, nmFile):
        self.nmFile = nmFile
        nm = sio.loadmat(nmFile)
        M = nm['M']
        N = nm['N']
        dapifile = str(M[0]['dapifile'][0][0])
        chans = M[0]['channels'][0][0]
        nChan = len(chans)
        imfiles = []
        channels = []
        for cc in range(0, nChan):
            channels.append(chans[cc][0])
            imfiles.append(dapifile.replace('dapi', chans[cc][0]))
        self.M = M
        self.N = N
        self.imfiles = imfiles
        self.channels = channels
        self.nNuclei = len(self.N[0].tolist())

    def getM(self):
        return(self.M)

    def getN(self):
        return(self.N)

    def getImFiles(self):
        return(self.imfiles)

    def getChannels(self):
        return(self.channels)
