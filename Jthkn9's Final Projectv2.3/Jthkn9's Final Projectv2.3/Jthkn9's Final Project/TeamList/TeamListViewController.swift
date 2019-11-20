import UIKit
import Foundation

protocol TeamListViewControllerDelegate: class {
    func playerAdded()
    func dataImported()
}

final class TeamListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    
    weak var delegate: TeamListViewControllerDelegate?
    
    private var model: TeamListModel!
    private var selectedTeam: Int = 0
    
}
extension TeamListViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let importButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(importTapped))
        self.navigationItem.setLeftBarButton(importButton, animated: true)
        
        let addPlayerButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPlayerTapped))
        self.navigationItem.setRightBarButton(addPlayerButton, animated: true)
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    static func instanceOfParent(model: TeamListModel) -> UINavigationController {
        let navigationController = UINavigationController.with(storyboardName: "TeamList")
        let viewController = navigationController.rootViewController(asType: TeamListViewController.self)
        viewController.setup(model: model)
        return navigationController
    }
    
    func setup(model: TeamListModel){
        self.model = model
    }
    
    @objc func addPlayerTapped() {
        performSegue(withIdentifier: "PlayerCreationView", sender: model.getTeamTupleArray())
    }
    
    @objc func importTapped(){
        let message: String = "Would you like to import data from json?"
        let title: String = "Import Data"
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: UIAlertAction.Style.default, handler: {[weak self](action) in alert.dismiss(animated: true, completion: nil)
            //print("Yes")
            self!.model.importTeamsFromJson()
            self!.dataRefreshed()
            self!.delegate?.dataImported()
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let teamViewController = segue.destination as? TeamViewController {
            guard let team = sender as? Team else {return}
            let teamModel = TeamModel(team: team)
            teamViewController.setup(model: teamModel)
        }
        else {
            guard let playerCreationViewController = segue.destination as? PlayerCreationViewController else {return}
            guard let teams = sender as? [(Int, String)] else {return}
    
        // dont pass the persistence. your model in this file already has persistence and should just get the stuff it needs first
            // pass the team ids and names (names for display)
            
            let teamsModel = PlayerCreationModel(teams: teams, delegate: self)
            playerCreationViewController.setup(model: teamsModel)
        }
    }
}

extension TeamListViewController: TeamModelDelegate {
    func save(player: Player) {
        // model.save(player: player) which will call persistence
        model.save(player: player)
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
         delegate?.playerAdded()
    }
}

extension TeamListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell")! as! TeamListTableViewCell
        cell.setup(with: model.getTeamAtIndex(atIndex: indexPath.row)!)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}

extension TeamListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTeam = indexPath.row
        performSegue(withIdentifier: "TeamView", sender: model.team(atIndex: indexPath.row))
    }
}

extension TeamListViewController: TeamListModelDelegate {
    func dataRefreshed() {
        tableView.reloadData()
    }
}

extension TeamListViewController: AllPlayersViewControllerDelegate {
    func playerDeleted() {
        // model pull the update from persistence
        model.importTeamsFromPersistance()
        tableView.reloadData()
    }
}
