//
//  MOSerViewController.m
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import "MOChasViewController.h"
#import "MOChaHandleViewController.h"
#import "MOBLEManager.h"

@interface MOChasViewController () <MOBLEManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *characteristics;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *nameLb;
@end

@implementation MOChasViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupView];
}

- (void)setService:(CBService *)service {
  _service = service;
  self.nameLb.text = @"discoverCharacteristics...";
  [self.tableView reloadData];
  [[MOBLEManager shareInstance] addDelegate:self];
  [[MOBLEManager shareInstance] discoverCharacteristicsForService:_service];
}

- (void)setupView {
  self.title = @"特性列表";
  CGFloat topHeight = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) + 44;
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight, self.view.frame.size.width, self.view.frame.size.height - topHeight) style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
  self.tableView.tableFooterView = view;
  [self.view addSubview:self.tableView];
}

#pragma mark - MOBLEManagerDelegate
- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
  self.service = service;
  if (error) {
    self.nameLb.text = [NSString stringWithFormat:@"获取特性失败:%@ %@", service.description, error.description];
  } else {
    self.nameLb.text = service.description;
  }
  [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  MOChaHandleViewController *vc = [MOChaHandleViewController new];
  CBCharacteristic *cha = self.service.characteristics[indexPath.row];
  [vc setCha:cha string:cell.textLabel.text];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIndentify = @"UITableViewCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentify];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentify];
  }
  cell.textLabel.font = [UIFont systemFontOfSize:14];
  cell.textLabel.numberOfLines = 0;
  cell.contentView.backgroundColor = indexPath.row % 2 == 0 ? UIColor.lightGrayColor : UIColor.whiteColor;
  CBCharacteristic *cha = self.service.characteristics[indexPath.row];
  NSString *string = [NSString stringWithString:cha.UUID.UUIDString];
  if (cha.value) {
    string = [string stringByAppendingString:@"\ndata:"];
    string = [string stringByAppendingString:[[NSString alloc] initWithData:cha.value encoding:NSUTF8StringEncoding]];
  }
  string = [string stringByAppendingString:@"\n"];
  if ((cha.properties & CBCharacteristicPropertyBroadcast) == CBCharacteristicPropertyBroadcast) {
    string = [string stringByAppendingString:@"/通知"];
  }
  if ((cha.properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead) {
    string = [string stringByAppendingString:@"/可读"];
  }
  if ((cha.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
    string = [string stringByAppendingString:@"/可写"];
  }
  if ((cha.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
    string = [string stringByAppendingString:@"/可写无反馈"];
  }
  if ((cha.properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify) {
    // 设备的蓝牙模块不需要等待手机蓝牙栈的回复
    string = [string stringByAppendingString:@"/可订阅无反馈"];
  }
  if ((cha.properties & CBCharacteristicPropertyIndicate) == CBCharacteristicPropertyIndicate) {
    // 设备的蓝牙模块需要等待手机蓝牙栈的回复才能下发下一条
    string = [string stringByAppendingString:@"/需要等待手机回复才能发送下一条"];
  }
  if ((cha.properties & CBCharacteristicPropertyAuthenticatedSignedWrites) == CBCharacteristicPropertyAuthenticatedSignedWrites) {
    string = [string stringByAppendingString:@"/通过验证的"];
  }
  if ((cha.properties & CBCharacteristicPropertyExtendedProperties) == CBCharacteristicPropertyExtendedProperties) {
    // 如果设置后，附加特性属性为一个扩展的属性说明
    string = [string stringByAppendingString:@"/拓展"];
  }
  if ((cha.properties & CBCharacteristicPropertyNotifyEncryptionRequired) == CBCharacteristicPropertyNotifyEncryptionRequired) {
    // 只有受信任的设备才能启用特征值的通知
    string = [string stringByAppendingString:@"/需要加密的通知"];
  }
  if ((cha.properties & CBCharacteristicPropertyNotifyEncryptionRequired) == CBCharacteristicPropertyNotifyEncryptionRequired) {
    // 只有受信任的设备可以启用特征值的指示
    string = [string stringByAppendingString:@"/需要加密的声明"];
  }
  cell.textLabel.text = string;
  
  // --- 方便测试
//  if ([cha.UUID.UUIDString containsString:@"8868"]) {
//    MOChaViewController *vc = [MOChaViewController new];
//    [vc setCha:cha string:string];
//    [self.navigationController pushViewController:vc animated:YES];
//  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.service.characteristics.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return self.headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 50;
}

- (UIView *)headerView {
  if (!_headerView) {
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    _headerView.backgroundColor = UIColor.whiteColor;
    [_headerView addSubview:self.nameLb];
    self.nameLb.center = _headerView.center;
  }
  return _headerView;
}

- (UILabel *)nameLb {
  if (!_nameLb) {
    _nameLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    _nameLb.textColor = UIColor.blueColor;
    _nameLb.font = [UIFont systemFontOfSize:14];
    _nameLb.numberOfLines = 0;
  }
  return _nameLb;
}

@end
