DragonBones DesignPanel V3.0.0 Release Notes
======================
中文版往后看

Dec 15th, 2014

DragonBones DesignPanel V3.0.0 is a big version after V2.4.1. In this version, we primary focused on customer experience improvement and bug fixing. 
All new features and improvements are based on customer feedback. If you have any ideas or suggestions, please email us dragonbonesteam@gmail.com.  

### New Features and Improvements
##### Add Animation Blending Time Settings in Import Panel.
* Animation blending time means: When armature switch animations, DragonBones can automatic generate tweens between animations.
* This setting item will work only if the original blending time haven't been set. If designer have set the blending time value before, the value will not be overrided.
* In previous version, the default blending time is 0.3 seconds. If you want it be 0 second, you need to manually set it for every animations one by one. In this version, you can conveniently set it in import panel with one time.

##### Separate the data format and texture format setting to two items in export panel
* In previous version, export format is one setting item. Along with the increase of supported data format and texture format, the list will blow up. So we separate it to two.
* Suggest user set these two items from up to down. Data format first, then texture format.

##### Support export AMF data format
* AMF(Action Message Format)is a Binary data format based on Flash technology. Because DragonBones can not encode or decode AMF itself, only Flash app makers are suggested use this format.

##### Add advanced setting items in export panel.
* The purpose of add advanced setting items is to provide more flexible configure for export. Usually the advanced settings are not necessary to be modified, because the default value can also ensure export successful. 
* Add 5 advanced setting items as following
1) Skeleton Data Name  
Skeleton data name is used as the default key to index skeleton data when it is added to factory. By default skeleton data name equals to FLA file name.  
2) Skeleton Data File Name  
The exported skeleton data file name. The default value is "skeleton". This setting item is available only if the data format is not Data Merged.
3) Texture Data File Name  
The exported texture data file name. The default value is "texture". This setting item is available only if the data format is not Data Merged.
4) Texture File Name  
The exported texture file name. The default value is "texture" This setting item is available only if the data format is not Data Merged.
5) Texture Atlas Path  
The texture atlas path is used to record the texture atlas' relative path. The default value is null. This setting item is useful only if there are a lot of texture atlas need to be dynamically load and they are located in different folder.

##### Armature view support drag to modify skeleton hierarchy.
* Click character in armature view to review the skeleton hierarchy.
* Click a bone in armature and drag to another bone to set its child.

##### Add Key Frame Auto Tween Switch in Animation Panel
* In previous version, DragonBones generate tweens between key frames automaticly unless there is a ^ in frame label. If you want to remove tweens in the whole animation, you need to add ^ in each key frame. 
* Key Frame Auto Tween Switch is open by default. If you close it, all tweens between key frames will be removed.

##### Improve Performance of Importing data from Flash Pro about 40%  
* Modify the mechanism of importing data from Flash Pro. There will be no Movie Clip generated in Flash Pro Library. 40% time will be reduced compared with previous version.

##### Don't support 2.2 or older data format any more
* Design Panel cannot open file with 2.2 or older data format.
* For projects using 2.2 data format, if you want to using DragonBones 3.0, you need to find the fla file and use DesignPanel 3.0 you export them. If your project have lots of assets, please be careful to make the decision.
* For files with 2.3 or later data formate, DesignPanel 3.0 can perfectly support them.

##### Pause support spine data format
* Considering the Spine data format has been changed for times. DesignPanel 3.0 cannot support it very well. So we decide to close it temporary. In future, along with DragonBones's upgrade, it may be added back. 


最近更新时间：2014年12月15日
### 概述
DragonBones DesignPanel V3.0.0 是V2.4.1之后的一个大版本。在这个版本中，我们主要聚焦于对用户体验的提升和bug的修复。  
所有的新功能改进都是基于我们收集的用户反馈。如果您对DragonBones有任何意见和建议，欢迎发邮件至dragonbonesteam@gmail.com。  

### 更新内容
##### 导入面板增加设置默认动画混合时间项目  
* 动画混合时间指：角色在切换动画时，DragonBones自动为角色生成的用于动画间动作过渡的时间。时间越长过度越平滑，时间设为0则没有过度。  
* 该设置项只会在混合时间没有设置的情况下起作用。如果设计师在导入前已经设置过某个动作的混合时间，则该设置项目不会在导入时覆盖原有的值。  
* 这个改动是基于大量的用户反馈，老版本默认动画混合时间是0.3秒，是不可设置的，很多用户希望动画间混合时间为0，则需要一个个的修改动作的混合时间，很麻烦。新版本就可以很方便的在导入时设置这个值了。  

##### 导出面板将数据格式和纹理格式的设置分为两个项目
* 老板本的导出格式是一个设置项，包含数据格式和纹理格式的排列组合。随着数据格式和纹理格式支持量的增加，这个列表会变的越来越长，所以新版本将其变为两个项目，希望用户能尽快适应。  
* 因为纹理格式列表会随着数据格式的选择而变化，所以在使用时最好从上至下，先设置数据格式，再设置纹理格式。

##### 导出面板增加AMF数据格式的支持
* AMF(Action Message Format)是Flash支持的一种二进制编码格式，他的体积会比xml和json小。因为DragonBones 本身不包含这种格式的解析，所以只建议开发Flash应用的用户使用这种格式。  

##### 导出面板增加高级选项
* 增加高级选项，目的在于为导出功能提供了更灵活的配置，一般情况下是不用修改的，因为默认值已经可以保证导出功能的正常工作。
* 增加如下5个高级设置项目  
1) 骨架数据名  
骨架数据名用于当骨架数据被添加到工厂时提供的用于数据索引的默认名称。该名称也可在数据被添加到工厂的代码中修改。默认情况下，骨架数据名等于FLA文件名。  
2)骨架数据文件名  
导出的骨架数据文件的文件名，默认值为“skeleton”。该选项只有在数据格式不为集成数据时才有效，因为导出集成数据时，骨架数据是集成到纹理文件中的，没有独立的骨架数据文件导出。  
3) 纹理数据文件名  
导出的纹理数据文件名，默认值为“texture”。该选项只有在数据格式不为集成数据时才有效，因为导出集成数据时，纹理数据是集成到纹理文件中的，没有独立的纹理数据文件导出。  
4) 纹理文件名  
导出的纹理文件名，默认值为“texture”。该选项只有在数据格式不为集成数据时才有效，因为导出集成数据时，文件名是在保存对话框中设置的。  
5) 纹理集路径  
纹理集路径可以用于记录纹理文件的相对路径，默认值为空。这个选项只有在纹理集很多，需要动态加载，并且放在不同的目录时才会有用，可以帮助开发者记录纹理集的相对路径。  

##### 骨架预览区域支持拖拽修改骨架关系
* 点击骨架预览区的角色可以查看骨架关系。
* 骨架预览区域选择父骨头，拖拽将箭头指向子骨头，实现骨架关系的修改。

##### 动画面板增加关键帧自动补间开关
* 关键帧自动补间指：属于同一个动画中相邻关键帧是否自动添加补间。
* 老板本中，DragonBones会默认进行关键帧自动补间，除非该关键帧标签上有^存在。如果希望实现整个动作都没有关键帧补间，需要在每个关键帧上加^帧标签。新版本将让这个效果的实现变的很方便。
* 关键帧自动补间开关默认是开启的。如果关闭，则该动画所有关键帧之间都没有补间，相当于每个关键帧上都有^。

##### 提升从Flash Pro导入数据的速度约40%
* 修改从FlashPro中导入数据的机制，在FlashPro的Library中将不再生成影片剪辑用于存储纹理,导入时间缩短约40%。

##### 不再兼容2.2及更老版本的数据格式
* 考虑到性能问题，以及2.3及以上版本的DragonBones已有较高的覆盖率，3.0版本将不再支持2.2及更老板本的数据格式。DesignPanel将无法打开不支持的数据格式文件。
* 对于已有的使用2.2版本数据格式的项目，需要找到fla源文件使用新版本的DesignPanel重新导出。如果您的项目素材量比较大，并且已经进入稳定期，建议您谨慎升级。
* 对于2.3及以后的版本的数据格式，DesignPanel 3.0可以无缝支持。

##### 暂停对Spine数据格式的支持
* 鉴于Spine的数据格式变化比较快，功能也愈加复杂，DesignPanel 3.0已经无法很好的支持Spine的数据格式，所以暂时关闭了这个功能。随着以后DragonBones功能的升级，这个功能有可能会加回来。  

### 安装步骤
#####  一般安装方法
* 确定您已经安装相同版本相同语言的Adobe Flash Pro 和Adobe Extension Manager. (例如，您的Flash Pro 版本是CC 2014中文版, 则您的Extension Manager 也必须是CC2014中文版)  
* 双击DragonBonesDesignPanel.zxp，启动ExtensionManager完成安装。
* 重启Flash Pro

如果使用以上方法安装失败，请检查您Extension Manager 左侧应用栏中能否招到Flash Pro的图标。如果Extension Manager 左侧应用栏中没有Flash Pro的图标，说明您的Flash Pro没有被系统检测到（Flash Pro 绿色版）必须使用终极安装方法。  

##### 终极安装方法
* 找到下面的目录：_"C:\Users\<用户>\AppData\Local\Adobe\<Flash Pro 版本>\<语言>\Configuration\WindowSWF"_ (Windows 用户)
* 将DragonBonesDesignPanel.zxp 改名为DragonBonesDesignPanel.zip 并解压缩。
* 将解压缩出来的文件拷贝至第1步找到的目录中，形成如下目录结构：  
_"第1步找到的目录\DragonBonesDesignPanel.swf"_  
_"第1步找到的目录\DragonBonesDesignPanel\xxx.jsfl"_  
* 重启Flash Pro  

