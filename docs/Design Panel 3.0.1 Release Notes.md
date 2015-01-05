DragonBones DesignPanel V3.0.1 Release Notes
======================
中文版往后看

Jan 5th, 2015

DragonBones DesignPanel V3.0.1 is a community experience version (minor version). In this version, we primary focused on data format standard upgrade based on downward compatibility as well as export feature improvement.  
All these features will be hold in community experience version for months before merge to stable version based on customer feedback. If you have any ideas or suggestions, please email us dragonbonesteam@gmail.com.  

### New Features  
##### Data Format Standard Upgrade  
* Data format standard upgraded to 3.0. Major changes as following:  
1) Add relative parent data format standard.   
2) Add default value standard  
* See details in  

##### Support export relative parent data format  
* Add a “Data Coordinate” option in Export panel. Support global coordinate and parent coordinate.  
* Note: Exported parent coordinate data, its skeleton hierarchy cannot be edit after open in DesignPanel again. Also it only can be parsed with 3.0.1 Library or above version.  

##### Support export compressed data.  
* Add a “Compress Data” switch in Export panel. Support compress data before export it.  
* Compressed exported data may not be correctly parsed with 3.0.0 or older version library.  

最近更新时间：2014年1月5日  
### 概述
DragonBones DesignPanel V3.0.1 是V3.0.0之后的一个社区体验版(小版本)。在这个版本中，我们主要做的是，在保持向下兼容的基础上扩展了数据格式，同时强化了导出功能。  
这个部分的功能会在社区体验版中过渡一段时间，之后基于用户反馈决定是否加入正式版。如果您对DragonBones有任何意见和建议，欢迎发邮件至dragonbonesteam@gmail.com。  

### 更新内容  
##### 升级了数据格式标准  
* 数据格式标准升级到3.0版本，主要变化如下：  
1) 增加相对Parent的数据格式标准  
DragonBones数据格式起源于FlashPro导出，3.0版本之前数据格式中所有的数据一直都是相对Global的数据。优点是能够最好的描述FlashPro中的动画数据，可以重新打开修改骨架关系甚至导回到FlashPro中再次编辑(考虑到版权保护，该功能还未开放)。缺点是数据量比较大而且不容易和其他骨骼引擎兼容。  
为了解决这些问题，3.0版本数据在原有数据格式标准不变的情况下，在根节点增加属性“isGlobal”作为开关，支持isGlobal=0的情况下，保存相对Parent的数据。这样(结合下面的新特性)数据量能够被更大程度的压缩，同时能够更方便的和Spine,CocosStudio的数据格式之间做转换。  
2) 增加默认值标准
增加默认值标准的目的是为了最大限度的压缩导出的数据量。当一个属性有默认值时，该属性就是个可选属性，如果该属性不存在，系统会自动将该属性的值视为默认值。这样在做数据导出时，就可以把所有等于默认值的属性从数据文件中删除，最大限度的压缩文件尺寸。  
* 详细的数据标准文档参见： [DragonBonesDataFormatSpec_V3.0_cn.xml](DragonBonesDataFormatSpec_V3.0_cn.xml)

##### 支持导出相对Parent的数据格式  
* 导出面板增加数据坐标系选项，支持Global坐标系和Parent坐标系。选择Global坐标系相当于导出和老板本的数据，选择Parent坐标系可以使骨架数据和动画数据都变为相对数据。  
* 注意：导出的Parent数据在被DesignPanel再次打开后，骨架关系是无法被修改的，而且只能被3.0.1或以上版本的Library解析。  

##### 支持导出压缩数据
* 导出面板增加压缩数据开关，支持通过将所有数值为默认值的属性删除的方式进行数据压缩。  
* 注意：压缩的数据有可能无法被老板本Library正确解析。  


