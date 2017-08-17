//
//  Octree.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 8/16/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation

class Octree {
    /**
     * treeEdgeSize: the max. bounding cube's edge length (at root level), in RESOLUTION units
     */
    let DEFAULT_TREE_EDGESIZE = 512
    /**
     * The voxel resolution in mm. This parameter determines the visual resolution of the app
     */
    let DEFAULT_LEAF_RESOLUTION = 20;
    //
    // dimensional data, initialized to their default values by the constructor or to
    // custom values when a tree is created from log-data
    var treeEdgeSize: Int
    var leafResolution: Int
    //
    // the root
    var root: InnerNode
    //
    // center of the octree, in resolution units. Is 0,0,0 at the beginning, but
    // changes if a new root replaces the origin in case of insertion at the top
    // (dynamic boundary adaption)
    var rootCenterX, rootCenterY, rootCenterZ: Int
    //
    // Array of leaves
    var leaves = [LeafNode]()
    //
    // temporary variables for recursion
    var tempParent: InnerNode
    var tempIndex: Int
    //
    // statistics
    var numberOfPoints = 0;
    var numberOfLeaves = 0;
    var numberOfInnerNodes = 0;
    var minX, minY, maxX, maxY, minZ, maxZ: Int16
    
    /// Init
    init(){
        treeEdgeSize = DEFAULT_TREE_EDGESIZE
        leafResolution = DEFAULT_LEAF_RESOLUTION
        root = InnerNode()
        rootCenterX = 0
        rootCenterY = 0
        rootCenterZ = 0
        tempParent = InnerNode()
        tempIndex = 0
        minX = Int16.max
        minY = Int16.max
        minZ = Int16.max
        maxX = Int16.min
        maxY = Int16.min
        maxZ = Int16.min
    }
    
    /**
     * ---------------------------------------------------------------------------------------------
     * Single Point Insertion, the core of the Octree functionality. Called from addPoints().
     *
     * @param x    point coordinate in mm
     * @param y    point coordinate in mm
     * @param z    point coordinate in mm
     * @param ARGB point color
     */
    func insert(x: Float, y: Float, z: Float) {
        numberOfPoints = numberOfPoints + 1
        //
        // convert x,y,z from meters to RESOLUTION units (RESOLUTION is defined in mm)
        let ix = Int16(floor(x * 1000.0 / Float(leafResolution)));
        let iy = Int16(floor(y * 1000.0 / Float(leafResolution)));
        let iz = Int16(floor(z * 1000.0 / Float(leafResolution)));
        //
        // check Octree boundaries and extend tree as long as the current boundaries
        // are too limiting
        var ediv2 = treeEdgeSize / 2;
        while (ix < rootCenterX - ediv2 || ix >= rootCenterX + ediv2 ||
            iy < rootCenterY - ediv2 || iy >= rootCenterY + ediv2 ||
            iz < rootCenterZ - ediv2 || iz >= rootCenterZ + ediv2) {
                // EXTEND TREE
                dynamicBoundaryAdaption(ix, iy, iz);
                //
                ediv2 = ediv2 * 2;
        }
        //
        // hashing: before stepping into the tree, check hash-table if the node has been cashed.
        // resulting Leaf is in htReturnLeaf
        // In case of a hit, nothing has to be done.
        //int hashValue = 0;
        //if (HASHING_ON) {
        //    hashValue = hashTable.checkEntry(ix, iy, iz);
        //    if (hashTable.htReturnLeaf != null) {
        // if leaf was hit: only a color update is needed!
        // update color of leaf, done.
        //updateColor(hashTable.htReturnLeaf, ARGB);
        // note 1: the chunk's color and colors of general parent inner nodes are NOT updated.
        // They receive a new color value each time a new point is added through the root,
        // not the hashtable.
        // note 2: a chunk does not need to be invalidated here, since no new VOXEL was created.
        // note 3: hashing and bales: If a point is inserted through the hash, it does, in
        // contrast to insertion through the root, not invalidate the bale. This creates an
        // interesting case: an initial voxel creation is always through the root, and hence
        // invalidates the bale. Follow up updates through the hash are added to a bale
        // correctly marked as invalid (i.e., to be stored to IM). However, if a bale is
        // transferred to IM, and at a later stage is reloaded into RAM, it is marked as
        // valid. If a voxel of that reloaded bale is still in the hash, any updates
        // will not mark the bale as invalid, i.e. they are lost when leaving the bale-culling
        // volume (if no other voxel was updated). This case is so rare and unimportant, that
        // it will be neglected, since a remedy would be very expensive (=> storing
        // references to bales along with the voxel references in the hashtable).
        //return;
        //    }
        // }
        //
        // Hashing did not retrieve a leaf
        // Step into the tree to insert leaf
        // Note: The new leaf is already created and inserted into the hashtable by hashTable.checkEntry()
        var current = root
        var centerX = rootCenterX
        var centerY = rootCenterY
        var centerZ = rootCenterZ
        var offset = treeEdgeSize / 4
        var indX = 0, indY = 0, indZ = 0, cellIndex = 0
        //
        // iterative stepping into the tree, no recursion needed for insertion
        var maxDepthReached = false;
        repeat {
            // no matter if we add an inner node or a leaf, we do add a child
            // to the current leaf => create array of children if not existent
            if (current.children == nil) {
                current.children = [Node?](repeating: nil, count: 8)
            }
            //
            // compute childIndex
            indX = ix < centerX ? 0 : 1;
            indY = iy < centerY ? 0 : 1;
            indZ = iz < centerZ ? 0 : 1;
            cellIndex = indX + 2 * indY + 4 * indZ;
            //
            maxDepthReached = (offset < 1);
            if (maxDepthReached) {
                // we are one level above max depth <=> offset < RESOLUTION
                // => add LEAF to octree (and end iteration)
                //
                // two cases: new leaf (insert), or existing leaf hit (merge)
                // the merge case should usually be detected by the hashing routine. However,
                // hashing can miss the merge case if the leaf was previously replaced, i.e.
                // removed from the hash due to collision
                //
                // case 1: New leaf, insert.
                if (current.children![cellIndex] == nil) {
                    // insert leaf into octree
                    // THIS IS THE ONE AND ONLY PLACE IN THE OCTREE WHERE A LEAF IS INSERTED
                    let leaf = LeafNode(ix, iy, iz);
                    current.children![cellIndex] = leaf;
                    //
                    // statistics
                    if (ix < minX) {minX = ix};
                    if (ix > maxX) {maxX = ix};
                    if (iy < minY) {minY = iy};
                    if (iy > maxY) {maxY = iy};
                    if (iz < minZ) {minZ = iz};
                    if (iz > maxZ) {maxZ = iz};
                    numberOfLeaves = numberOfLeaves + 1
                    leaves.append(leaf)
                }
                // case 2: existing leaf, merge (nothing to do!)
                else {
                    // nothing (yet)
                }
                //
                // insert leaf into hashtable
                //if (HASHING_ON) {
                //    hashTable.insert(hashValue, leaf);
                //}
            } else {
                // Inner Node.
                // Update center and offset
                centerX += offset * (indX * 2 - 1)
                centerY += offset * (indY * 2 - 1)
                centerZ += offset * (indZ * 2 - 1)
                offset /= 2
                //
                // insert inner node, if it does not exist yet
                if (current.children![cellIndex] == nil) {
                    let inner = InnerNode()
                    current.children![cellIndex] = inner
                    numberOfInnerNodes = numberOfInnerNodes + 1;
                }
                // step one level down
                current = current.children![cellIndex] as! InnerNode;
            }
        } while (!maxDepthReached);
    }
    
    
    /**
     * ---------------------------------------------------------------------------------------------
     * Dynamic Boundary Adaption
     * Extends the outer boundary-edgelength of the entire octree by a factor of two.
     * When a point to be inserted lies outside of the current boundaries, this routine is called
     * until the tree reaches a sufficient dimension.
     * Extend Tree creates a new root (with new root-center) and attaches the current root according
     * to the insertion point location, i.e. the new root is created at a location towards the
     * insertion point.
     * input: insertion point ix, iy, iz in resolution units
     * Note: this routine increases the depth of the tree by one, yet does not change the resolution
     */
    func dynamicBoundaryAdaption(_ ix: Int16, _ iy: Int16, _ iz: Int16) {
        // determine child-index, at which the current root will be attached
        let indX = ix < rootCenterX ? 0 : 1;
        let indY = iy < rootCenterY ? 0 : 1;
        let indZ = iz < rootCenterZ ? 0 : 1;
        var cellIndex = indX + 2 * indY + 4 * indZ; // forward index
        cellIndex = 7 - cellIndex;                  // backward index
        //
        // compute center of new root
        // This changes the root-location of the octree!
        rootCenterX += treeEdgeSize / 2 * (indX * 2 - 1);
        rootCenterY += treeEdgeSize / 2 * (indY * 2 - 1);
        rootCenterZ += treeEdgeSize / 2 * (indZ * 2 - 1);
        //
        // create new root
        let newRoot = InnerNode();
        newRoot.children = [Node?](repeating: nil, count: 8);
        //
        // attach old root, replace by new root
        // Do this only, if root already had children, i.e. there was already a point stored,
        // otherwise the root will become an inner node with children = null (which is forbidden)
        if (root.children != nil) {
            newRoot.children![cellIndex] = root;
        }
        // here is the actual extension:
        root = newRoot;
        treeEdgeSize *= 2;
    }
}

